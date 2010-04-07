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
