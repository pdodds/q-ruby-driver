require File.expand_path(
        File.join(File.dirname(__FILE__), %w[.. lib q-ruby-driver]))

include QRubyDriver

# RSpec tests require a live Q instance to which we can connect.
# See TestUnit tests for a self-contained test

describe QRubyDriver do

  HOST, PORT = "localhost", 5001

  it "should allow a basic Q connection to a Q instance" do
    q_conn = QConnection.new HOST, PORT
    q_conn.close
  end

  it "should allow us to send a hand crafted message via a Q connection with async" do
    q_conn = QConnection.new HOST, PORT
    q_conn.send_raw("01000000120000000a0004000000613a6062")
    q_conn.close
  end

  it "should allow us to send a hand crafted message via a Q connection with sync" do
    q_conn = QConnection.new HOST, PORT
    q_conn.send_raw("01010000110000000a0003000000613a31")
    q_conn.close
  end

  it "should allow us to get a String" do
    q_conn = QConnection.new HOST, PORT
    response = q_conn.get("2+2")
    q_conn.close
    response.should.== 4
    puts response
  end

  it "should allow us to get a variable to set its value" do
    q_conn = QConnection.new HOST, PORT
    q_conn.get("a:`cheesy")
    response = q_conn.get("a")
    q_conn.close
    response.should.== "cheesy"
  end

  it "should allow us to get a dictionary" do
    q_conn = QConnection.new HOST, PORT
    response = q_conn.get("`a`b!2 3")
    q_conn.close
    response.should.is_a? Hash
    response.length.should.== 2
    response["a"].should.== 2
    response["b"].should.== 3

    puts response.inspect
  end

  it "should allow us to get vectors" do
    q_conn = QConnection.new HOST, PORT
    q_conn.get("a:`IBM`GOOG`APPL")
    response = q_conn.get("a")
    q_conn.close
    response.should.is_a? Array
    response.length.should.== 3
    response[0].should.== "IBM"
    response[1].should.== "GOOG"
    response[2].should.== "APPL"

    puts response.inspect
  end

  it "should allow us to create a 1,000,000 trades" do
    q_conn = QConnection.new HOST, PORT
    q_conn.get("""trade:(	[]date:`date$();
	   	time:`time$();
		sym:`symbol$();
		price:`float$();
		size:`int$();
		exchange:`symbol$();
		c:()
		);
    """)
    q_conn.get("portfolio:`IBM`GOOG`VOD`BA`AIB`MSFT`BOI / define variable portfolio")
    q_conn.get("countries:(portfolio!`USA`USA`UK`USA`IRL`USA`IRL) / some countries")
    q_conn.get("dts: .z.D-til 200 / A few dates")
    q_conn.get("st: 09:30:00.000 / market open")
    q_conn.get("et: 16:00:00.000 / market close")
    q_conn.get("exchanges:`N`L`O`C / Some exchanges")
    q_conn.get("n:1000000 / The number of trades to create")
    response = q_conn.get("\\t insert[`trade;(n?dts;st+n?et-st;n?portfolio;n?100f;n?1000;n?exchanges;n?.Q.A,'reverse .Q.a)] / create 1m random trades")

    puts "Created a million trades in #{response}ms"

    response = q_conn.get("count trade")
    response.should.== 1000000
    q_conn.close
  end

  it "should allow us to select from the trades table" do
    q_conn = QConnection.new HOST, PORT
    response = q_conn.get("select max price by sym from trade")
    response.keys[0].length.should.== 1

    puts response.inspect
    
    response[response.keys[0]]["price"].length.should.== 7
    response.keys[0]["sym"].length.should.== 7
    response.keys[0]["sym"].include?("GOOG").should.== true
    response.keys[0]["sym"].include?("BA").should.== true
    response.keys[0]["sym"].include?("BOI").should.== true
    response.keys[0]["sym"].include?("IBM").should.== true
    response.keys[0]["sym"].include?("MSFT").should.== true
    response.keys[0]["sym"].include?("VOD").should.== true
    response.keys[0]["sym"].include?("CHEESE").should.== false
    
    q_conn.close
  end

  it "should support getting functions" do
    q_conn = QConnection.new HOST, PORT
    response = q_conn.get("show_me:{[something] show something;show_me};")
    puts response
    q_conn.get("show_me(`hello)")

    q_conn.close
  end
  

  it "should return exceptions" do
    q_conn = QConnection.new HOST, PORT
    begin
      q_conn.get("somethingmissing")
    rescue QRubyDriver::QException => e
      puts e.message
    end
    q_conn.close
  end

  it "should be able to handle multi-type dictionaries" do
    q_conn = QConnection.new HOST, PORT
    response = q_conn.get("(`b,1)!(`a,3)")
    q_conn.close
    response.should.is_a? Hash
    response.length.should.== 2

    response["b"].should.== "a"
    response[1].should.== 3

  end

  it "should be able to handle lists" do
    q_conn = QConnection.new HOST, PORT
    response = q_conn.get("enlist til 5")
    q_conn.close
    response.should.is_a? Array
    response.length.should.== 1
    response[0].should.is_a? Array

    response[0][0].should.== 0
    response[0][1].should.== 1
    response[0][2].should.== 2
    response[0][3].should.== 3
    response[0][4].should.== 4

  end

  it "should support character arrays" do
    q_conn = QConnection.new HOST, PORT
    response = q_conn.get("\"hello\"")
    q_conn.close
    
    response.should.is_a? Array
    response.length.should.== 5
    response.should.== "hello"
  end

#  it "should be able to support arrays as parameters" do
#    q_conn = QConnection.new HOST, PORT
#    values = ["a",1,2,3,4,5]
#    response = q_conn.get(values)
#    response.length.should.==values
#    q_conn.close
#  end

end

