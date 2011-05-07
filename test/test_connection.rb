require './test_helper'
require 'test/unit'
require 'socket'

# Tests the socket connection using a dummy server
# which gives a spoof response

class TestConnection < Test::Unit::TestCase

  HOST = "127.0.0.1"
  @@port = 12300

  def setup
    @@serv = TCPServer.new(HOST, @@port)
  end

  def teardown
    @@conn.close
    @@port += 1
  end

  # helper methods
  def string_to_int_array(str)
    str.each_byte.map{|x| x}
  end

  def test_async
    request = "Hello world!"
    Thread.new() {
      # listen for initial connection
      s = @@serv.accept
      s.recv(100)
      s.write ['0','1','0','2'].pack('H4')
      sleep(1) # wait a bit
      expected = [1, 0, 0, 0, request.length+14, 0, 0, 0, 10, 0, request.length, 0, 0, 0] + string_to_int_array(request)
      assert_equal(expected,string_to_int_array(s.recv(100)))
    }
    @@conn=QRubyDriver::QConnection.new(HOST, @@port)
    @@conn.set(request)
    sleep(5)
    assert(true)
  end

  def test_sync
    request = "Hello world!"
    obj = ["foo",[91,34],["bar",[true,false,true]]]
    Thread.new() {
      # listen for initial connection
      s = @@serv.accept
      s.recv(100)
      s.write ['0','1','0','2'].pack('H4')
      sleep(1) # wait a bit
      expected = [1, 1, 0, 0, request.length+14, 0, 0, 0, 10, 0, request.length, 0, 0, 0] + string_to_int_array(request)
      assert_equal(expected,string_to_int_array(s.recv(100)))
      qio=QRubyDriver::QIO.new()
      qio.write_message(obj, :response)
      qio.pos=0
      s.write qio.read
    }
    @@conn=QRubyDriver::QConnection.new(HOST, @@port)
    assert_equal(obj, @@conn.get(request))
  end
end