require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','common_controllers.rb'))

describe "module Esda::Scaffolding::Destroy" do
  controller_name :customer
  context "test with data" do
    before(:each) do
      @cust = mock_model(Customer)
      @cust.should_receive(:destroy)
      Customer.should_receive(:find).with("12345").and_return(@cust)
    end
    it "should should remove data from the database" do
      post :destroy, :id=>12345
    end
    it "should redirect according to redirect_to parameter" do
      url = "/foo/bar"
      post :destroy, :id=>12345, :redirect_to=>url
      response.should redirect_to(url)
    end
  end
  it "should render a 404 if called without id" do
    post :destroy
    response.response_code.should == 404
  end
end

