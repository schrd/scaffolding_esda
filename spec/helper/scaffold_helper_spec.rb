require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','common_controllers.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','common_models.rb'))
describe Esda::Scaffolding::Helper::ScaffoldHelper, :type=>:helper do
  context "scaffold_value" do
    it "should escape values" do
      cust = Customer.new(:name=>'"foo">')
      ret=helper.scaffold_value(cust, :name)
      ret.should == "&quot;foo&quot;&gt;"
    end
    it "should link to belongs_to values" do
      cust = Customer.create(:name=>'"foo>')
      cust.should_receive(:scaffold_name).and_return('"foo>')
      order = Order.new(:customer=>cust)
      ret = helper.scaffold_value(order, :customer)
      ret.should == %{<a href="/customer/show/#{cust.id}">&quot;foo&gt;</a>}
    end
    it "should format :text columns in a div.pre block" do
      cust = Customer.new(:detailed_description=>%{"foo\nbar>})
      ret = helper.scaffold_value(cust, :detailed_description)
      ret.should == %{<div class="pre">&quot;foo\nbar&gt;</div>}
    end
  end
end
