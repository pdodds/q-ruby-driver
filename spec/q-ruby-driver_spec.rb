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

  it "should allow us to get vectors" do
    q_instance = QInstance.new 5001
    q_instance.get("a:`IBM`GOOG`APPL")
    response = q_instance.get("a")
    q_instance.close
    response.value.should.is_a? Array
    response.value.length.should.== 3
    response.value[0].should.== "IBM"
    response.value[1].should.== "GOOG"
    response.value[2].should.== "APPL"

    puts response.value.inspect
  end

  it "should allow us to create a 1,000,000 trades" do
    q_instance = QInstance.new 5001
    q_instance.get("""trade:(	[]date:`date$();
	   	time:`time$();
		sym:`symbol$();
		price:`float$();
		size:`int$();
		exchange:`symbol$();
		c:()
		);
    """)
    q_instance.get("portfolio:`IBM`GOOG`VOD`BA`AIB`MSFT`BOI / define variable portfolio")
    q_instance.get("countries:(portfolio!`USA`USA`UK`USA`IRL`USA`IRL) / some countries")
    q_instance.get("dts: .z.D-til 200 / A few dates")
    q_instance.get("st: 09:30:00.000 / market open")
    q_instance.get("et: 16:00:00.000 / market close")
    q_instance.get("exchanges:`N`L`O`C / Some exchanges")
    q_instance.get("n:1000000 / The number of trades to create")
    response = q_instance.get("\\t insert[`trade;(n?dts;st+n?et-st;n?portfolio;n?100f;n?1000;n?exchanges;n?.Q.A,'reverse .Q.a)] / create 1m random trades")

    puts "Created a million trades in #{response.value}ms"

    response = q_instance.get("count trade")
    response.value.should.== 1000000
    q_instance.close
  end

  it "should allow us to select from the trades table" do
    q_instance = QInstance.new 5001
    response = q_instance.get("select max price by sym from trade")
    response.value.keys[0].length.should.== 1

    puts response.value.inspect
    
    response.value[response.value.keys[0]]["price"].length.should.== 7
    response.value.keys[0]["sym"].length.should.== 7
    response.value.keys[0]["sym"].include?("GOOG").should.== true
    response.value.keys[0]["sym"].include?("BA").should.== true
    response.value.keys[0]["sym"].include?("BOI").should.== true
    response.value.keys[0]["sym"].include?("IBM").should.== true
    response.value.keys[0]["sym"].include?("MSFT").should.== true
    response.value.keys[0]["sym"].include?("VOD").should.== true
    response.value.keys[0]["sym"].include?("CHEESE").should.== false
    
    q_instance.close
  end

  it "should support getting functions" do
    q_instance = QInstance.new 5001
    response = q_instance.get("show_me:{[something] show something;show_me};")
    puts response
    q_instance.get("show_me(`hello)")

    q_instance.close
  end
  

  it "should return exceptions" do
    q_instance = QInstance.new 5001
    begin
      q_instance.get("somethingmissing")
    rescue QRubyDriver::QException => e
      puts e.q_message.value
    end
    q_instance.close
  end

  it "should be able to handle multi-type dictionaries" do
    q_instance = QInstance.new 5001
    response = q_instance.get("(`b,1)!(`a,3)")
    q_instance.close
    response.value.should.is_a? Hash
    response.value.length.should.== 2

    response.value["b"].should.== "a"
    response.value[1].should.== 3

  end

  it "should be able to handle lists" do
    q_instance = QInstance.new 5001
    response = q_instance.get("enlist til 5")
    q_instance.close
    response.value.should.is_a? Array
    response.value.length.should.== 1
    response.value[0].should.is_a? Array

    response.value[0][0].should.== 0
    response.value[0][1].should.== 1
    response.value[0][2].should.== 2
    response.value[0][3].should.== 3
    response.value[0][4].should.== 4

  end

  it "should support character arrays" do
    q_instance = QInstance.new 5001
    response = q_instance.get("\"hello\"")
    q_instance.close
    
    response.value.should.is_a? Array
    response.value.length.should.== 5
    response.value.should.== "hello"
  end

#  it "should be able to support arrays as parameters" do
#    q_instance = QInstance.new 5001
#    values = ["a",1,2,3,4,5]
#    response = q_instance.get(values)
#    q_instance.close
#
#  end



end

