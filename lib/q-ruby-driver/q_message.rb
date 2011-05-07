module QRubyDriver

  # Provided for legacy compatibility with previous versions of q-ruby-driver
  # Usage of this class is deprecated
  class QMessage

    attr :message_type
    attr :exception
    attr :value
    attr :message_type
    attr :message
    attr :timing

    @exception = false

    def create(value, sync = false)
      @value = value
      sync == true ? @message_type = :sync : @message_type = :async

      start_time = Time.now

      qio = QIO.new
      qio.write_message(value, sync)
      qio.pos=0
      @message = qio.read
      puts [@message].inspect
      @length = @message.length
      @timing = Time.now - start_time

      self
    end

    # Decodes a binary message into a QMessage
    def decode(message)
      start_time= Time.now
      @message = message
      qio = QIO.new(@message)
      begin
        @length, @message_type = qio.message_header()
        @value = qio.read_item()
      rescue QException => qe
        @exception = qe
      end
    end

    def to_s
      if @message.nil?
        "QMessage [None]"
      elsif !@exception.nil?
        "QException [#{@message.unpack("H*")}] Type[#{@message_type}] Length [#{@length}] Value[#{@value}]"
      else
        "QMessage [#{@message.unpack("H*")}] Type[#{@message_type}] Length [#{@length}] Value[#{@value}]"
      end
    end

  end
end