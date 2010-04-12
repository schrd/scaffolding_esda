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

describe "module Esda::Scaffolding::Browse", "browse_data action" do
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
    Order.should_receive(:scaffold_browse_fields).at_least(:once).and_return(%w(order_number customer.customer_number))
    Order.should_receive(:find).with(:all, :limit=>50, :conditions=>["1=1 AND customers.customer_number = ?", 12345], :order=>nil, :include=>[{:customer=>[]}], :offset=>0)
    get :browse_data, {:limit=>50, :search=>{:order=>{"customer.customer_number"=>"12345"}}}  
    response.content_type.should == "application/json"
  end

  it "should use localized date parameters (de)" do
    I18n.locale = "de"
    d = Date.new(2010,3,2)
    Order.should_receive(:scaffold_browse_fields).at_least(:once).and_return(%w(order_number customer.customer_number deliver_until))
    Order.should_receive(:find).with(:all, :limit=>50, :conditions=>["1=1 AND orders.deliver_until >= ?", d], :order=>nil, :include=>[{:customer=>[]}], :offset=>0)
    get :browse_data, {:limit=>50, :search=>{:order=>{"deliver_until"=>{"from"=>"02.03.2010"}}}}
    response.content_type.should == "application/json"
  end
  it "should use localized date parameters (en)" do
    I18n.locale = :en
    I18n.default_locale = :en
    d = Date.new(2010,3,2)
    I18n.t(:"date.formats.default").should == "%Y-%m-%d"
    Order.should_receive(:scaffold_browse_fields).at_least(:once).and_return(%w(order_number customer.customer_number deliver_until))
    Order.should_receive(:find).with(:all, :limit=>50, :conditions=>["1=1 AND orders.deliver_until >= ?", d], :order=>nil, :include=>[{:customer=>[]}], :offset=>0)
    get :browse_data, {:limit=>50, :search=>{:order=>{"deliver_until"=>{"from"=>"2010-03-02"}}}}
    response.content_type.should == "application/json"
  end

  it "should let the database sort data" do
    Order.should_receive(:scaffold_browse_fields).at_least(:once).and_return(%w(order_number customer.customer_number))
    Order.should_receive(:find).with(:all, :limit=>50, :conditions=>["1=1 AND customers.customer_number = ?", 12345], :order=>"orders.order_number ASC", :include=>[{:customer=>[]}], :offset=>0)
    get :browse_data, {:limit=>50, :search=>{:order=>{"customer.customer_number"=>"12345"}}, :sort=>"order_number ASC"}  
    response.content_type.should == "application/json"
  end
  it "should let the database sort data even for included columns" do
    Order.should_receive(:scaffold_browse_fields).at_least(:once).and_return(%w(order_number customer.customer_number))
    Order.should_receive(:find).with(:all, :limit=>50, :conditions=>["1=1 AND customers.customer_number = ?", 12345], :order=>"customers.customer_number ASC", :include=>[{:customer=>[]}], :offset=>0)
    get :browse_data, {:limit=>50, :search=>{:order=>{"customer.customer_number"=>"12345"}}, :sort=>"customer.customer_number ASC"}  
    response.content_type.should == "application/json"
  end

end
