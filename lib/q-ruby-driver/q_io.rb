module QRubyDriver

  # @author John Shields
  # Single-pass Ruby reader/writer for byte-streams in Q IPC protocol format
  class QIO < StringIO

    # Q type constants
    Q_ATOM_TYPES     = -19..-1
    Q_VECTOR_TYPES   = 1..19
    Q_TYPE_EXCEPTION = -128
    Q_TYPE_BOOLEAN   = -1
    Q_TYPE_BYTE      = -4
    Q_TYPE_SHORT     = -5
    Q_TYPE_INT       = -6
    Q_TYPE_LONG      = -7
    Q_TYPE_REAL      = -8   # single-prec float
    Q_TYPE_FLOAT     = -9   # double-prec float
    Q_TYPE_CHAR      = -10
    Q_TYPE_SYMBOL    = -11
    Q_TYPE_TIMESTAMP = -12
    Q_TYPE_MONTH     = -13
    Q_TYPE_DATE      = -14
    Q_TYPE_DATETIME  = -15
    Q_TYPE_TIMESPAN  = -16
    Q_TYPE_MINUTE    = -17
    Q_TYPE_SECOND    = -18
    Q_TYPE_TIME      = -19
    Q_TYPE_CHAR_VECTOR= 10
    Q_TYPE_SYMBOL_VECTOR= 11
    Q_TYPE_LIST      = 0
    Q_TYPE_FLIP      = 98
    Q_TYPE_DICTIONARY= 99

    # Read methods

    # Decodes a binary Q message into Ruby types
    def read_message()
      self.read(8) # skip message header
      return read_item
    end

    # Extracts length and message type from the message header
    def read_message_header
      header = self.read(8).unpack("H2H2H4I")
      length = header[3]
      case header[1]
        when "00" then
          msg_type = :async
        when "01" then
          msg_type = :sync
        when "02" then
          msg_type = :response
      end
      return length, msg_type
    end

    # Reads the next item and extracts it into a Ruby type
    # Will extract vectors, dictionaries, lists, etc. recursively
    def read_item(type = nil)
      type = read_byte() if type.nil?
      case type
        when Q_TYPE_EXCEPTION then
          raise QException.new(read_symbol)
        when Q_ATOM_TYPES then
          return read_atom(type)
        when Q_TYPE_LIST then
          return read_list
        when Q_VECTOR_TYPES then
          return read_vector(type)
        when Q_TYPE_FLIP then
          return read_flip
        when Q_TYPE_DICTIONARY then
          return read_dictionary
        when 100 then
          read_symbol
          return read_item
        when 101..103 then
          return read_byte == 0 && type == 101 ? nil : "func";
        when 104 then
          read_int.times { read_item }
          return "func"
        when 105..255 then
          read_item
          return "func"
        else
          raise "Cannot read unknown type #{type}"
      end
    end

    # Complex type handlers

    # Reads a vector into a Ruby Array
    def read_vector(type)
      length = self.read(5).unpack("c1I")[1]
      byte_type, num_bytes = get_atom_pack(-type)

      if type==Q_TYPE_SYMBOL_VECTOR
        raw = length.times.map{ self.readline("\x00") }.inject{|str, n| str + n}
        value = raw.unpack(byte_type*length)
      else
        raw = self.read(length*num_bytes)
        value = raw.unpack(byte_type+length.to_s)
      end

      # char vectors are returned as strings
      # all other types are returned as arrays
      (type == Q_TYPE_CHAR_VECTOR) ? value[0] : value.map{|i| atom_to_ruby(i, -type)}
    end

    # Reads a dictionary into a Ruby Hash
    def read_dictionary
      # The first item is a vector containing the dictionary keys
      keys = read_item
      keys = [keys] unless keys.is_a? Array

      # The second item is a list containing the values of each key
      values = read_item
      values = [values] unless values.is_a? Array

      hash = {}
      keys.zip(values) { |k,v| hash[k]=v }
      return hash
    end

    # Decodes a flip table into a Ruby Hash
    def read_flip
      self.read(1)
      read_item   # should be a dictionary
    end

    # Decodes a list into an array
    def read_list
      length = self.read(5).unpack("c1I")[1]
      length.times.map { read_item }
    end

    # Extracts atom types into Ruby types
    def read_atom(type)
      raise QIOException.new "Cannot read atom type #{type}" unless (type>=-19 and type<0)
      byte_type, num_bytes = get_atom_pack(type)
      raw = (type==Q_TYPE_SYMBOL) ? self.readline("\x00") : self.read(num_bytes)
      value = raw.unpack(byte_type)[0]

      atom_to_ruby(value, type)
    end

    # Extracts atom types into Ruby types
    def atom_to_ruby(value, type)
      case type
        when Q_TYPE_BOOLEAN then
          boolean_to_ruby value
        # TODO: add support for date/time types
        else
          value
      end
    end

    # Atom type handlers
    def boolean_to_ruby value
      value==1
    end

    # Short cut methods for reading atoms
    def read_boolean
      read_atom(Q_TYPE_BOOLEAN)
    end
    def read_byte
      read_atom(Q_TYPE_BYTE)
    end
    def read_short
      read_atom(Q_TYPE_SHORT)
    end
    def read_int
      read_atom(Q_TYPE_INT)
    end
    def read_long
      read_atom(Q_TYPE_LONG)
    end
    def read_real
      read_atom(Q_TYPE_REAL)
    end
    def read_float
      read_atom(Q_TYPE_FLOAT)
    end
    def read_char
      read_atom(Q_TYPE_CHAR)
    end
    def read_symbol
      read_atom(Q_TYPE_SYMBOL)
    end
    def read_timestamp
      read_atom(Q_TYPE_TIMESTAMP)
    end
    def read_month
      read_atom(Q_TYPE_MONTH)
    end
    def read_date
      read_atom(Q_TYPE_DATE)
    end
    def read_datetime
      read_atom(Q_TYPE_DATETIME)
    end
    def read_timespan
      read_atom(Q_TYPE_TIMESPAN)
    end
    def read_minute
      read_atom(Q_TYPE_MINUTE)
    end
    def read_second
      read_atom(Q_TYPE_SECOND)
    end
    def read_time
      read_atom(Q_TYPE_TIME)
    end

    # Write methods

    # Writes a Ruby object to a Q message
    def write_message(message, msg_type=:async)
      offset = self.pos
      self.write ["01"].pack("H*")
      self.write case msg_type
        when :async    then ["00"].pack("H*")
        when :sync     then ["01"].pack("H*")
        when :response then ["02"].pack("H*")
        else raise QIOException.new("Cannot write unknown message type #{msg_type.to_s}")
      end
      self.write ["0000"].pack("H*")
      self.pos += 4 # will write size here
      write_item(message)
      # write size
      size = self.pos - offset
      self.pos = offset+4
      write_int(size)
      # set position to end of buffer
      self.pos = offset + size
    end

    # Helper method to infer Q type from native Ruby types
    def get_q_type(item)
      if item.is_a? Exception
        Q_TYPE_EXCEPTION
      elsif item.is_a?(TrueClass) || item.is_a?(FalseClass)
        Q_TYPE_BOOLEAN
      elsif item.is_a? Bignum
        Q_TYPE_LONG
      elsif item.is_a? Fixnum
        Q_TYPE_INT
      elsif item.is_a? Float
        Q_TYPE_FLOAT
      elsif item.is_a? String
        Q_TYPE_CHAR_VECTOR
      elsif item.is_a? Symbol
        Q_TYPE_SYMBOL
      # not yet supported
#      elsif item.is_a? Date
#        Q_TYPE_DATE
#      elsif item.is_a? DateTime
#        Q_TYPE_DATETIME
#      elsif item.is_a? Time
#        Q_TYPE_TIME
      elsif item.is_a? Array
        get_q_array_type(item)
      elsif item.is_a? Hash
        Q_TYPE_FLIP
      else
        raise QIOException.new("Cannot infer Q type from #{item.class.to_s}")
      end
    end

    # Helper method to write a Ruby array into either a list or a vector,
    # depending on whether or not the array contains mixed types
    def get_q_array_type(array)
      raise QIOException.new("Cannot write empty array") if array.empty?

      klass = array[0].class
      return 0 if klass==String # String is a vector type; cannot make a vector of vectors

      if klass==TrueClass || klass==FalseClass # special routine for booleans
        array.each do |item|
          return 0 unless item.is_a?(TrueClass) || item.is_a?(FalseClass)
        end
      else
        array.each do |item|
          return 0 unless item.is_a? klass
        end
      end

      -1 * get_q_type(array[0])
    end

    # Encodes a type into the IPC representation
    # no native support for  the following atom types: byte, short, real, char
    def write_item(item, type=nil)
      type=get_q_type(item) if type.nil?
      write_type type
      case type
        when Q_TYPE_EXCEPTION then
          write_exception item
        when Q_ATOM_TYPES then
          write_atom item, type
        when Q_TYPE_LIST then
          write_list item
        when Q_TYPE_CHAR_VECTOR then
          write_string item
        when 1..9, 11..19 then # Q_VECTOR_TYPES minus Q_TYPE_CHAR_VECTOR
          write_vector item, type
        when Q_TYPE_FLIP then
          write_flip item
        when Q_TYPE_DICTIONARY then
          write_dictionary item
        else
          raise QIOException.new "Cannot write type #{type}"
      end
    end

    # Writes the type byte
    def write_type(type)
      self.write [type].pack("c1")
    end

    # Encodes an array as a vector
    def write_vector(array, type=nil)
      raise QIOException("Cannot write empty vector") if array.empty?
      type = -1 * get_q_type(array[0]) if type.nil?
      self.write ["00", array.length].pack("H1I")
      if type==Q_TYPE_SYMBOL_VECTOR
        array.each{|x| self.write [ruby_to_atom(x, -type)].pack( get_atom_pack(-type)[0] ) }
      else
        self.write array.map{|x| ruby_to_atom(x, -type)}.pack( get_atom_pack(-type)[0] + array.length.to_s )
      end
    end

    # Encodes a string as a char vector
    def write_string(item)
      value = item.is_a?(String) ? item.scan(/./) : item  # convert string into a char array
      self.write ["00", value.length].pack("H1I")
      self.write value.pack("A"*value.length)
    end

    # Encodes a list
    def write_list(array)
      raise QIOException("Cannot write empty list") if array.empty?
      self.write ["00", array.length].pack("H1I1")
      array.each { |item| write_item(item) }
    end

    # Encodes a dictionary
    def write_dictionary(hash)
      write_type Q_TYPE_SYMBOL_VECTOR
      write_vector hash.keys, Q_TYPE_SYMBOL_VECTOR
      write_type Q_TYPE_LIST
      write_list hash.values
    end

    # Encodes a flip table
    def write_flip(hash)
      self.write ["00"].pack("H1")
      write_item(hash, 99) # dictionary
    end

    # Encodes atom types
    def write_atom(value, type)
      raise QIOException.new "Cannot write atom type #{type}" unless ((type>=-19 and type<0) || type==Q_TYPE_EXCEPTION)
      self.write [ruby_to_atom(value, type)].pack(get_atom_pack(type)[0])
    end

    # Returns pack type and byte-length of q atom type
    def get_atom_pack(type)
      case type
        when Q_TYPE_BOOLEAN, Q_TYPE_BYTE then
          ['c',1]
        when Q_TYPE_SHORT then
          ['s',2]
        when Q_TYPE_INT, Q_TYPE_MONTH, Q_TYPE_DATE, Q_TYPE_MINUTE, Q_TYPE_SECOND, Q_TYPE_TIME  then
          ['I',4]
        when Q_TYPE_LONG, Q_TYPE_TIMESTAMP, Q_TYPE_TIMESPAN then
          ['q',8]
        when Q_TYPE_REAL then
          ['F',4]
        when Q_TYPE_FLOAT, Q_TYPE_DATETIME then
          ['D',8]
        when Q_TYPE_CHAR then
          ['Z',1]
        when Q_TYPE_SYMBOL, Q_TYPE_EXCEPTION then
          ['Z*',0]
        else
          raise QIOException.new "Unknown atom type #{type}"
      end
    end

    def ruby_to_atom(value, type)
      case type
        when Q_TYPE_BOOLEAN then
          ruby_to_boolean value
        when Q_TYPE_SYMBOL then
          ruby_to_symbol value
        when Q_TYPE_EXCEPTION then
          ruby_to_exception value
        else
           value
      end
    end

    def ruby_to_boolean(value)
      if value.is_a? TrueClass
        1
      elsif value.is_a? FalseClass
        0
      else
        value == true
      end
    end
    def ruby_to_symbol(value)
      value.to_s
    end
    def ruby_to_exception(value)
      if value.is_a? Exception
        value.message
      else
        value.to_s
      end
    end

    # Atom type write shortcut methods
    def write_boolean(value)
      write_atom(value, Q_TYPE_BOOLEAN)
    end
    def write_byte(value)
      write_atom(value, Q_TYPE_BYTE)
    end
    def write_short(value)
      write_atom(value, Q_TYPE_SHORT)
    end
    def write_int(value)
      write_atom(value, Q_TYPE_INT)
    end
    def write_long(value)
      write_atom(value, Q_TYPE_LONG)
    end
    def write_real(value)
      write_atom(value, Q_TYPE_REAL)
    end
    def write_float(value)
      write_atom(value, Q_TYPE_FLOAT)
    end
    def write_char(value)
      write_atom(value, Q_TYPE_CHAR)
    end
    def write_symbol(value)
      write_atom(value, Q_TYPE_SYMBOL)
    end
    def write_exception(value)
      write_atom(value, Q_TYPE_EXCEPTION)
    end
    def write_timestamp(value)
      write_atom(value, Q_TYPE_TIMESTAMP)
    end
    def write_month(value)
      write_atom(value, Q_TYPE_MONTH)
    end
    def write_date(value)
      write_atom(value, Q_TYPE_DATE)
    end
    def write_datetime(value)
      write_atom(value, Q_TYPE_DATETIME)
    end
    def write_timespan(value)
      write_atom(value, Q_TYPE_TIMESPAN)
    end
    def write_minute(value)
      write_atom(value, Q_TYPE_MINUTE)
    end
    def write_second(value)
      write_atom(value, Q_TYPE_SECOND)
    end
    def write_time(value)
      write_atom(value, Q_TYPE_TIME)
    end
  end
end