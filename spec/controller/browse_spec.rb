require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','common_controllers.rb'))

describe "module Esda::Scaffolding::Browse", "browse action" do
  controller_name :customer
  it "should render the browse template" do
    get :browse
    response.should render_template("browse")
    assigns[:model].should == Customer
  end

  it "should handle extra parameters for invisible columns" do
    Customer.should_receive(:scaffold_no_browse_columns).and_return(["customer_number"])
    get :browse, {"search"=>{"customer"=>{"customer_number"=>"123"}}}
    assigns[:model].should == Customer
    assigns[:extra_params].should == "search[customer][customer_number]=123&link=true"
    response.should render_template("browse")
  end

  it "should not handle extra parameters for visible columns" do
    get :browse, {"search"=>{"customer"=>{"customer_number"=>"123"}}}
    assigns[:model].should == Customer
    assigns[:extra_params].should == "&link=true"
    response.should render_template("browse")
  end
end

describe "module Esda::Scaffolding::Browse", "browse action" do
  controller_name :order
  before(:each) do
    @order = mock_model(Order)
  end
  it "should call find without conditions if no parameters are specified" do
    Order.should_receive(:find).with(:all, :limit=>50, :conditions=>["1=1"], :order=>nil, :include=>[], :offset=>0)
    get :browse_data, {:limit=>50}
    assigns[:model].should == Order
  end

  it "should call find with conditions" do
    Order.should_receive(:scaffold_browse_fields).at_least(:once).and_return(%w(order_numer customer.customer_number))
    Order.should_receive(:find).with(:all, :limit=>50, :conditions=>["1=1 AND customers.customer_number = ?", 12345], :order=>nil, :include=>[{:customer=>[]}], :offset=>0)
    get :browse_data, {:limit=>50, :search=>{:order=>{"customer.customer_number"=>"12345"}}}  
    response.content_type.should == "application/json"
  end

end
