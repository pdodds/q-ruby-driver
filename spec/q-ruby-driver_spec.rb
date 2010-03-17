require File.expand_path(
        File.join(File.dirname(__FILE__), %w[.. lib q-ruby-driver]))

include QRubyDriver

describe QRubyDriver do

  it "should allow a basic connection to a Q instance" do
    q_instance = QInstance.new 5001
    q_instance.close
  end

  it "should allow us to send a hand crafted message to a Q instance with async" do
    q_instance = QInstance.new 5001
    q_instance.send_raw("01000000120000000a0004000000613a6062")
    q_instance.close
  end

  it "should allow us to send a hand crafted message to a Q instance with sync" do
    q_instance = QInstance.new 5001
    q_instance.send_raw("01010000110000000a0003000000613a31")
    q_instance.close
  end

  it "should allow us to get a String" do
    q_instance = QInstance.new 5001
    response = q_instance.get("2+2")
    q_instance.close
    response.value.should.== 4
    puts response
  end

  it "should allow us to get a variable to set its value" do
    q_instance = QInstance.new 5001
    q_instance.get("a:`cheesy")
    response = q_instance.get("a")
    q_instance.close
    response.value.should.== "cheesy"
  end

  it "should allow us to get a dictionary" do
    q_instance = QInstance.new 5001
    response = q_instance.get("`a`b!2 3")
    q_instance.close
    response.value.should.is_a? Hash
    response.value.length.should.== 2
    response.value["a"].should.== 2
    response.value["b"].should.== 3

    puts response.value.inspect
  end

  it "should allow us to get a dictionary from a select" do
    q_instance = QInstance.new 5001
    response = q_instance.get("select * from `.")
    q_instance.close
    response.value.should.is_a? Hash

    puts response.value.inspect
  end


end

