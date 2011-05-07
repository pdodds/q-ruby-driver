module QRubyDriver
  
  # An exception which was raised by the Q service itself, originating
  # from the server-side
  class QException < RuntimeError

    attr_reader :message

    def initialize(message)
      @message = message
    end
  end

  # An exception which occurs on the client-side (within this app)
  # during the I/O processing of Q messages
  class QIOException < RuntimeError

    attr_reader :message

    def initialize(q_message)
      @message = message
    end
  end
end