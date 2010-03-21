module QRubyDriver

  class QException < RuntimeError

    attr :q_message

    def initialize(q_message)
      @q_message = q_message
    end

  end

end