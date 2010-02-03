require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','common_controllers.rb'))

describe "module Esda::Scaffolding::Show", "show action" do
  controller_name :customer
  it "should generate a show action" do
    customer = mock_model(Customer)
    Customer.should_receive(:find).with("123").and_return(customer)
    get :show, :id=>123
    assigns[:instance].should == customer
    response.should render_template('show')
  end
  it "should return 404 if called without id" do
    get :show
    response.response_code.should == 404
  end
end
describe "module Esda::Scaffolding::Show", "download action" do
  controller_name :customer
  it "should send binary data as application/octet-stream as default" do
    customer = mock_model(Customer)
    data = "This would be the binary photo"
    customer.should_receive(:photo).and_return(data)
    Customer.should_receive(:find).with("123").and_return(customer)
    get :download_column, :id=>123, :column=>'photo'
    response.content_type.should == "application/octet-stream"
    response.body.should == data
  end
  it "should send binary data with a custom mime type" do
    customer = mock_model(Customer)
    data = "This would be the binary photo"
    customer.should_receive(:photo).and_return(data)
    customer.should_receive(:mime_type_for_photo).and_return("image/jpeg")
    Customer.should_receive(:find).with("123").and_return(customer)
    get :download_column, :id=>123, :column=>'photo'
    response.content_type.should == "image/jpeg"
    response.body.should == data
  end
end
