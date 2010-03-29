require 'socket'

module QRubyDriver
  class QInstance

    # Initializes the connection
    def initialize(port, host = "localhost", username = ENV['USER'])
      @client_socket = TCPSocket.new(host, port)
      @client_socket.write [username, "001"].pack("a*H")
      @client_socket.recv(1024).unpack("H*")
    end

    # Sync Send
    def get(obj)
      @client_socket.write QMessage.new().create(obj, true).message
      build_response(@client_socket.recv(10000000))
    end

    # ASync send
    def set(obj)
      @client_socket.write QMessage.new().create(obj).message
    end

    # Takes a hex encoded representation of the message to send
    def send_raw(raw_message)
      encoded_message = [raw_message].pack("H*")
      @client_socket.write encoded_message

      if (encoded_message[1] == 1)
        build_response(@client_socket.recv(10000000))
      else
        nil
      end
    end

    # Closes the connection
    def close
      @client_socket.close
    end

    private

    def build_response(response)
      qresponse = QMessage.new().decode(response)
      if (qresponse.exception)
        puts qresponse
        raise QRubyDriver::QException.new qresponse
      else
        qresponse
      end
    end

  end
end