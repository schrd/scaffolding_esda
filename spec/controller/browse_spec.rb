require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','common_controllers.rb'))

describe "module Esda::Scaffolding::Browse" do
  controller_name :customer
  it "should call find without conditions" do
    get :browse
    response.should render_template("browse")
    assigns[:model].should == Customer
  end

  it "should handle extra parameters for invisible columns" do
    Customer.should_receive(:scaffold_no_browse_columns).and_return(["customer_number"])
    get :browse, {"search"=>{"customer"=>{"customer_number"=>"123"}}}
    assigns[:model].should == Customer
    assigns[:extra_params].should == "search[customer][customer_number]=123&link=true"
  end

  it "should not handle extra parameters for visible columns" do
    get :browse, {"search"=>{"customer"=>{"customer_number"=>"123"}}}
    assigns[:model].should == Customer
    assigns[:extra_params].should == "&link=true"
  end
end
