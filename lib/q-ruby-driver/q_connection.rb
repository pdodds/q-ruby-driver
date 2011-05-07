require 'socket'

module QRubyDriver
  class QConnection

    @@BUFFER_SIZE = 2048

    # Initializes the connection
    def initialize(host="localhost", port=3000, username = ENV['USER'])
      @client_socket = TCPSocket.new(host, port)
      @client_socket.write [username, "001"].pack("a*H")
      @client_socket.recv(4).unpack("H*")
    end

    # Sync Send
    def get(obj)
      write_to_socket(obj, true)
      read_from_socket()
    end
    alias :execute :get

    # ASync send
    def set(obj)
      write_to_socket(obj, false)
    end

    # Takes a hex encoded representation of the message to send
    def send_raw(raw_message, sync=true)
      encoded_message = [raw_message].pack("H*")
      @client_socket.write encoded_message

      if (encoded_message[1] == 1)
        read_from_socket()
      else
        nil
      end
    end

    # Dumps table schema
    def table_info(table_name)
      get("meta #{table_name}")
    end

    # Closes the connection
    def close
      @client_socket.close
    end

    private

    def write_to_socket(obj, sync=true)
      qio = QIO.new
      qio.write_message(obj, sync ? :sync : :async)
      qio.pos=0
      @client_socket.write qio.read
    end

    def read_from_socket()
      qio = buffered_recv()
      qio.read_message
    end

    def buffered_recv()
      # peek at the total message length
      peek = @client_socket.recvfrom(8, Socket::MSG_PEEK)
      length = QIO.new(peek[0]).read_message_header[0]

      # read up to full message length
      qio = QIO.new()
      while qio.length < length
        qio.write @client_socket.recvfrom(@@BUFFER_SIZE)[0]
      end
      qio.pos=0
      return qio
    end

  end
end