require './test_helper'
require 'test/unit'

# These tests do round-trip integration testing
# (i.e. write then read) on the QIO class
class TestIO < Test::Unit::TestCase

  def setup
    @qio=QRubyDriver::QIO.new()
  end

  # helper methods
  def string_to_int_array(str)
    str.each_byte.map{|x| x}
  end

  def test_string
    str="This is a %1$5#!@-ing string"

    expected=[1, 0, 0, 0, str.length+14, 0, 0, 0, 10, 0, 28, 0, 0, 0]+string_to_int_array(str)

    @qio.write_message(str)
    @qio.pos=0
    assert_equal(expected, string_to_int_array(@qio.read()))
    @qio.pos=0
    assert_equal(str, @qio.read_message())
  end

  def test_int
    int=1

    expected=[1, 0, 0, 0, 13, 0, 0, 0, 250, 1, 0, 0, 0]

    @qio.write_message(int)
    @qio.pos=0
    assert_equal(expected, string_to_int_array(@qio.read()))
    @qio.pos=0
    assert_equal(int, @qio.read_message())
  end

  def test_float
    float=3.68423

    expected=[1, 0, 0, 0, 17, 0, 0, 0, 247, 97, 137, 7, 148, 77, 121, 13, 64]

    @qio.write_message(float)
    @qio.pos=0
    assert_equal(expected, string_to_int_array(@qio.read()))
    @qio.pos=0
    assert_equal(float, @qio.read_message())
  end

  def test_symbol
    sym="This is a %1$5#!@-ing symbol".to_sym
    expected=[1, 0, 0, 0, 38, 0, 0, 0, 245]+string_to_int_array(sym.to_s)+[0]

    @qio.write_message(sym)
    @qio.pos=0
    assert_equal(expected, string_to_int_array(@qio.read()))
    @qio.pos=0
    assert_equal(sym.to_s, @qio.read_message())
  end

  def test_exception
    exc=Exception.new("This is an exception")
    expected=[1, 0, 0, 0, 30, 0, 0, 0, 128]+string_to_int_array(exc.message)+[0]

    @qio.write_message(exc)
    @qio.pos=0
    assert_equal(expected, string_to_int_array(@qio.read()))
    @qio.pos=0

    # should throw the exception when reading
    begin
      @qio.read_message()
    rescue QRubyDriver::QException => qe
      assert_equal(exc.message, qe.message)
    end
  end

  def test_int_vector
    vector=[1,3]

    expected=[1, 0, 0, 0, 22, 0, 0, 0, 6, 0, 2, 0, 0, 0, 1, 0, 0, 0, 3, 0, 0, 0]

    @qio.write_message(vector)
    @qio.pos=0
    assert_equal(expected, string_to_int_array(@qio.read()))
    @qio.pos=0
    assert_equal(vector, @qio.read_message())
  end

  def test_bool_vector
    vector=[true,false,true]

    msg_header=[1, 0, 0, 0, 17, 0, 0, 0]
    bool_vector =  [1, 0, 3, 0, 0, 0, 1, 0, 1]
    expected=msg_header+bool_vector

    @qio.write_message(vector)
    @qio.pos=0
    assert_equal(expected, string_to_int_array(@qio.read()))
    @qio.pos=0
    assert_equal(vector, @qio.read_message())
  end

  def test_symbol_vector
    vector=[:symbol1, :symbol2, :symbol3]

    msg_header = [1, 0, 0, 0, 38, 0, 0, 0]
    sym_vector = [11, 0, 3, 0, 0, 0]+vector.map{|x| string_to_int_array(x.to_s)+[0]}.flatten
    expected=msg_header+sym_vector
    
    @qio.write_message(vector)
    @qio.pos=0
    assert_equal(expected, string_to_int_array(@qio.read()))
    @qio.pos=0
    assert_equal(vector.map{|x|x.to_s}, @qio.read_message())
  end

  def test_list
    list=["foo",[91,34],["bar",[true,false,true]]]

    msg_header =   [1, 0, 0, 0, 61, 0, 0, 0]
    list1_header = [0, 0, 3, 0, 0, 0]
    string_foo =   [10, 0, 3, 0, 0, 0] + string_to_int_array("foo")
    int_vector =   [6, 0, 2, 0, 0, 0, 91, 0, 0, 0, 34, 0, 0, 0]
    list2_header = [0, 0, 2, 0, 0, 0]
    string_bar =   [10, 0, 3, 0, 0, 0] + string_to_int_array("bar")
    bool_vector =  [1, 0, 3, 0, 0, 0, 1, 0, 1]
    expected=msg_header+list1_header+string_foo+int_vector+list2_header+string_bar+bool_vector

    @qio.write_message(list)
    @qio.pos=0
    assert_equal(expected, string_to_int_array(@qio.read()))
    @qio.pos=0
    assert_equal(list, @qio.read_message())
  end

  def test_flip
    hash={:foo => [91,34, 20], :bar => [true,false,true], :woof => ["beatles","stones","zeppelin"], :meow => [:how, :now, :cow]}

    msg_header =   [1, 0, 0, 0, 131, 0, 0, 0]
    flip_dict_header = [98, 0, 99]
    sym_vector_1 = [11, 0, 4, 0, 0, 0] + hash.keys.map{|x|string_to_int_array(x.to_s)+[0]}.flatten
    list_header = [0, 0, 4, 0, 0, 0]
    int_vector =   [6, 0, 3, 0, 0, 0, 91, 0, 0, 0, 34, 0, 0, 0, 20, 0, 0, 0]
    bool_vector =   [1, 0, 3, 0, 0, 0, 1, 0, 1]
    # I'm not actually sure if "char_vector_list" is the correct IPC format
    # but it is my expectation for now until I learn otherwise
    char_vector_list =   [0, 0, 3, 0, 0, 0] + hash[:woof].map{|x| [10, 0, x.length, 0, 0, 0] + string_to_int_array(x.to_s)}.flatten
    sym_vector_2 = [11, 0, 3, 0, 0, 0] + hash[:meow].map{|x|string_to_int_array(x.to_s)+[0]}.flatten

    expected = msg_header + flip_dict_header + sym_vector_1 + list_header + int_vector + bool_vector + char_vector_list + sym_vector_2

    @qio.write_message(hash)
    @qio.pos=0
    assert_equal(expected, string_to_int_array(@qio.read()))
    @qio.pos=0

    expected_hash={}
    hash.keys.each {|k| expected_hash[k.to_s]=hash[k]}
    expected_hash['meow'] = expected_hash['meow'].map{|x|x.to_s}

    assert_equal(expected_hash, @qio.read_message())
  end
end