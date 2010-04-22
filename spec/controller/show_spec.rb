require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','common_controllers.rb'))

describe "module Esda::Scaffolding::Show", "show action" do
  controller_name :customer
  context "test with data" do
    before(:each) do
      @customer = mock_model(Customer)
      Customer.should_receive(:find).with("123").and_return(@customer)
    end
    after(:each) do
      assigns[:instance].should == @customer
    end
    it "should generate a show action" do
      get :show, :id=>123
      response.should render_template('show')
    end
    it "should render the inline template if its a xhr" do
      xhr :get, :show, :id=>123
      response.should render_template('show_inline')
    end
    it "should respect inline actions" do
      Customer.should_receive(:inline_association).and_return("foo")
      get :show, :id=>123
      assigns[:inline_association].should == "foo"
      response.should render_template('show')
    end
  end
  context "error handling" do
    it "should return 404 if called without id" do
      get :show
      response.response_code.should == 404
    end
  end
end
describe "module Esda::Scaffolding::Show", "download action" do
  controller_name :customer
  before(:each) do
    @customer = mock_model(Customer)
  end
  context "test with data" do
    before(:each) do
      @data = "This would be the binary photo"
      @customer.should_receive(:photo).and_return(@data)
      Customer.should_receive(:find).with("123").and_return(@customer)
    end
    it "should send binary data as application/octet-stream as default" do
      get :download_column, :id=>123, :column=>'photo'
      response.content_type.should == "application/octet-stream"
      response.body.should == @data
    end
    it "should send binary data with a custom mime type" do
      @customer.should_receive(:mime_type_for_photo).and_return("image/jpeg")
      get :download_column, :id=>123, :column=>'photo'
      response.content_type.should == "image/jpeg"
      response.body.should == @data
    end
  end
  context "error handling" do
    after(:each) do
      response.response_code.should == 404
    end
    it "should return 404 if column does not exist" do
      Customer.should_not_receive(:find)
      get :download_column, :id=>123, :column=>'nonexistant_column'
    end
    it "should return 404 if column is non-binary" do
      Customer.should_not_receive(:find)
      get :download_column, :id=>123, :column=>'name'
    end
    it "should return 404 if record does not exist" do
      Customer.should_receive(:find).with("123").and_raise(ActiveRecord::RecordNotFound.new)
      get :download_column, :id=>123, :column=>'photo'
    end
  end
end
describe "module Esda::Scaffolding::Show", "history action" do
  controller_name :customer
  before(:each) do
  end
  context "real data processing" do
    before(:each) do
      Customer.primary_key = "customer_id"
      @cust = Customer.new
      # override id
      @cust.should_receive(:id).any_number_of_times.and_return(123)
      Customer.should_receive(:find).with("123").and_return(@cust)

    end
    it "should load most recent data" do
      Customer.primary_key = "customer_id"
      cust1 = Customer.new
      cust2 = Customer.new
      Customer.should_receive(:find_by_sql).with(["SELECT * FROM customers_log WHERE customer_id=? ORDER BY customers_log_id DESC LIMIT 2", "123"]).and_return([cust1, cust2])
      get :history, :id=>123
      response.should render_template("history")
      assigns[:instances].should == [@cust, cust1, cust2]
    end

    it "should load data before id x" do
      cust1 = Customer.new
      cust2 = Customer.new
      cust3 = Customer.new
      Customer.should_receive(:find_by_sql).with(["SELECT * FROM customers_log WHERE customer_id=? and customers_log_id < ? ORDER BY customers_log_id DESC LIMIT 3", "123", "2345"]).and_return([cust1, cust2, cust3])
      get :history, :id=>123, :before=>2345
      response.should render_template("history")
      assigns[:instances].should == [cust1, cust2, cust3]
    end

    it "should load data after id x" do
      cust1 = Customer.new
      cust2 = Customer.new
      cust3 = Customer.new
      Customer.should_receive(:find_by_sql).with(["SELECT * FROM customers_log WHERE customer_id=? and customers_log_id > ? ORDER BY customers_log_id DESC LIMIT 3", "123", "2345"]).and_return([cust1, cust2, cust3])
      get :history, :id=>123, :after=>2345
      response.should render_template("history")
      assigns[:instances].should == [cust1, cust2, cust3]
    end
    it "should display log data and current data if not enough log records exist" do
      cust1 = Customer.new
      cust2 = Customer.new
      Customer.should_receive(:find_by_sql).with(["SELECT * FROM customers_log WHERE customer_id=? and customers_log_id > ? ORDER BY customers_log_id DESC LIMIT 3", "123", "2345"]).and_return([cust1, cust2])
      get :history, :id=>123, :after=>2345
      response.should render_template("history")
      assigns[:instances].should == [@cust, cust1, cust2]
    end
  end
end
