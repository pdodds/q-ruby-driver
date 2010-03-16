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

    puts to_s
    self
  end

  # Decodes a binary message into a QMessage
  def decode(message)

    @message = message
    message_header = @message.unpack("H2H2H4I")
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
    type = value.unpack("c1")[0]
    decode_value = ""
    if (type>0 and type<99)
      # We have a vector
      payload = value[1..value.length+1]
      decode_value = decode_vector(type,payload,payload.length)
    elsif (type == 99)
      # We have a dictionary
      payload = value[1..value.length+1]
      decode_value = decode_dictionary(type,payload,payload.length)
    elsif (type == 101)
      # We have a confirmation message?
    elsif (type<0 and type>-128)
      payload = value[1..value.length+1]
      decode_value = decode_type(type,payload,payload.length)
    else
      throw "Unsupported type #{type}"
    end

    return decode_value
  end

  def decode_type(type,payload,length)
    case type
      when -128 then
        @exception = true
        return payload.unpack("A#{length}")[0]
      when -6 then
        return payload.unpack("I#{length}")[0]
      when -11 then
        return payload.unpack("A#{length}")[0]
      when -101 then
        return payload.unpack("A#{length}")[0]
      else
        throw "Unsupported type #{type} on message #{@message.unpack("H*")}"
    end
  end

  # Decodes a dictionary - which we will hold as a map in Ruby
  def decode_dictionary(type,payload,length)

    puts @message.unpack("H*")
    # In order to decode a dictionary we will basically create two arrays
    first_vector_result = decode_vector(payload,length)
    second_vector_result = decode_vector(payload,length)
  end

  def decode_vector(payload,length)
    vector_header = payload.unpack("c1I")
    puts "Vector type #{vector_header[0]} size #{vector_header[1]} #{payload.unpack("H*")}"

  end

end