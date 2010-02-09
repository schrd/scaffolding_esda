require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','common_controllers.rb'))

describe "module Esda::Scaffolding::Edit", "edit action" do
  controller_name :customer
  it "should render the edit template" do
    cust = Customer.new
    Customer.should_receive(:find).with("12345").and_return(cust)
    get :edit, :id=>12345
    assigns[:instance].should == cust
    response.should render_template("edit")
  end
  it "should not render the edit template if called inline" do
    cust = Customer.new
    Customer.should_receive(:find).with("12345").and_return(cust)
    get :edit, :id=>12345, :inline=>1
    assigns[:instance].should == cust
    response.should_not render_template("edit")
  end
  it "should render 404 if called without id" do
    get :edit
    response.response_code.should == 404
  end
end
describe "module Esda::Scaffolding::Edit", "update action" do
  controller_name :customer
  context "do real things" do
    before(:each) do
      @customer = mock_model(Customer)
      @customer.should_receive(:save!).and_return(true)
      @customer.should_receive(:"attributes=").with("customer_number"=>"23456")
      @customer.should_receive(:valid?).and_return(true)
      Customer.should_receive(:find).with("12345").and_return(@customer)
    end
    it "should save changes into the database" do
      post :update, :id=>12345, :customer=>{:customer_number=>"23456"}
      response.should render_template("edit")
    end
    it "should redirect according to redirect_to parameter" do
      url = "/foo/bar"
      post :update, :id=>12345, :customer=>{:customer_number=>"23456"}, :redirect_to=>url
      response.should redirect_to(url)
    end
  end
  it "should render 404 if called without id" do
    post :update
    response.response_code.should == 404
  end
end
