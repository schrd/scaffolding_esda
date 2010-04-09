require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','common_controllers.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','common_models.rb'))
describe Esda::Scaffolding::Helper::FormScaffoldHelper, :type=>:helper do
  context "show_record" do
    before(:each) do
      @customer = Customer.new(:customer_number=>1234, :name=>"foobar")
    end
    it "should render all fields" do
      get :foo
      ret = helper.record_show(@customer)
      ret.should have_tag("table")
      ret.should contain("1234")
      ret.should contain("foobar")
    end
    it "should render all fields except some" do
      get :foo
      ret = helper.record_show(@customer, :invisible_fields=>["name"])
      ret.should have_tag("table")
      ret.should contain("1234")
      ret.should_not contain("foobar")
    end
  end
  context "record_form" do
    before(:each) do
      @customer = Customer.new(:customer_number=>1234, :name=>"foobar")
    end
    it "should show all fields" do
      get :foo
      ret = helper.record_form(@customer)
      ret.should have_xpath("//input[@value='1234']")
      ret.should have_xpath("//input[@value='foobar']")
      ret.should_not have_xpath("//input[@name='invisible_fields[]']")
    end
    it "should render all fields except invisible (hidden) fields" do
      get :foo
      ret = helper.record_form(@customer, :invisible_fields=>["name"])
      ret.should have_xpath("//input[@value='1234' and @type='text']")
      ret.should have_xpath("//input[@value='foobar' and @type='hidden' and @name='customer[name]']")
      ret.should have_xpath("//input[@value='name' and @type='hidden' and @name='invisible_fields[]']")
    end
  end
end
