module QRubyDriver

  class QException < RuntimeError

    attr :q_message

    def initialize(q_message)
      @q_message = q_message
    end

    def message
      "QException [#{q_message.value}]"
    end

  end

end