module QRubyDriver

  class QMessage

    attr :message_type
    attr :exception
    attr :value
    attr :message_type
    attr :message

    def create(value, sync = false)

      # If we get given a string we are going to create an array of characters
      if (value.instance_of?(String))
        @value = value.scan(/./)
      else
        @value = value
      end


      @exception = false
      @message = ["01"].pack("H*")
      sync == true ? @message_type = :sync : @message_type = :async
      @message_type == :sync ? @message << ["01"].pack("H*") : @message << ["00"].pack("H*")
      @message << ["0000"].pack("H*")

      encoded_value = encode_value(@value)
      @length = encoded_value.length+8
      @message << [@length].pack("I")
      @message << encoded_value

      self
    end

    def unpack(pattern)
      result = @remaining_message.unpack(pattern)
      length_to_remove = result.pack(pattern).length
      @remaining_message = @remaining_message[length_to_remove..@remaining_message.length]
      result
    end

    # Decodes a binary message into a QMessage
    def decode(message)

      @message = message
      @remaining_message = @message
      message_header = unpack("H2H2H4I")

      @length = message_header[3]

      case message_header[1]
        when "01" then
          @message_type = :sync
        when "02" then
          @message_type = :response
        when "00" then
          @message_type = :async
      end

      @value = decode_value(message[8..@length])

      self
    end

    def to_s
      if @message.nil?
        "QMessage [None]"
      elsif @exception == true
        "QException [#{@message.unpack("H*")}] Type[#{@message_type}] Length [#{@length}] Value[#{@value}]"
      else
        "QMessage [#{@message.unpack("H*")}] Type[#{@message_type}] Length [#{@length}] Value[#{@value}]"
      end
    end

    private

    # Encodes a type into the IPC representation
    def encode_value(value)
      encoded_value = ""
      case value.class.to_s
        when "Fixnum" then
          encoded_value << [-6].pack("c1")
          encoded_value << [value].pack("I")
        when "String" then
          encoded_value << [-11].pack("c1")
          encoded_value << [value].pack("A*")
        when "Date" then
          encoded_value << [-14].pack("c1")
          encoded_value << [value].pack("A*")
        when "Time" then
          encoded_value << [-19].pack("c1")
          encoded_value << [value].pack("A")
        when "Array" then
          encoded_value = encode_array(value)
        else
          throw "Unsupported type #{value.class.to_s}"
      end

      return encoded_value
    end

    # Encodes an array
    def encode_array(value)
      # Assuming a char vector
      encoded_value = ""
      encoded_value << [10, "00", value.length].pack("c1H1I")
      encoded_value << value.pack("A"*value.length)

      return encoded_value
    end

    # Decodes an encoded value into a type
    def decode_value(value)
      type = unpack("c1")[0]
      decode_value = nil
      if (type>0 and type<99)
        # We have a vector
        decode_value = decode_vector(type)
      elsif (type == 99)
        # We have a dictionary
        decode_value = decode_dictionary
      elsif (type == 101)
        # We have a confirmation message?
      elsif (type<0)
        decode_value = decode_type(type)
      else
        throw "Unsupported type #{type}"
      end

      return decode_value
    end

    def decode_type(type)
      case type
        when -128 then
          @exception = true
          return unpack("A")[0]
        when -6 then
          return unpack("I")[0]
        when -11 then
          return  unpack("Z*")[0]
        when -101 then
          return unpack("A")[0]
        when -98 then
          return unpack("F")[0]
        when -0 then
          # TODO what is the 0 data type
          return unpack("c2")[0]
        else
          throw "Unsupported type #{type} on message #{@message.unpack("H*")}"
      end
    end

    # Decodes a dictionary - which we will hold as a hash in Ruby
    def decode_dictionary
      # In order to decode a dictionary we will basically create two arrays
      vector_type = unpack("c1")[0]
      first_vector_result = decode_vector(vector_type)
      first_vector_result = [first_vector_result] unless first_vector_result.is_a? Array
      second_vector_type = unpack("c1")[0]
      second_vector_result = decode_vector(second_vector_type)
      second_vector_result = [second_vector_result] unless second_vector_result.is_a? Array

      dictionary = {}
      (0..first_vector_result.length-1).each do |i|
        dictionary[first_vector_result[i]] = second_vector_result[i]
      end
      dictionary
    end

    # Decodes a vector into an array
    def decode_vector(type)
      vector_header = unpack("c1I")
      vector = []

      (1..vector_header[1]).each do
        vector << decode_type(-type)
      end

      vector
    end

  end
end