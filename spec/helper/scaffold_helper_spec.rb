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
    it "should display but not link belongs_to values" do
      cust = Customer.create(:name=>'"foo>')
      cust.should_receive(:scaffold_name).and_return('"foo>')
      order = Order.new(:customer=>cust)
      ret = helper.scaffold_value(order, :customer, false)
      ret.should == %{&quot;foo&gt;<span class="inlineshow" title="Customer" url="/customer/show/#{cust.id}"></span>}
    end
    it "should format :text columns in a div.pre block" do
      cust = Customer.new(:detailed_description=>%{"foo\nbar>})
      ret = helper.scaffold_value(cust, :detailed_description)
      ret.should == %{<div class="pre">&quot;foo\nbar&gt;</div>}
    end
    it "should follow associations" do
      cust = Customer.create(:name=>'"foo>')
      order = Order.new(:customer=>cust)
      ret = helper.scaffold_value(order, "customer.name")
      ret.should == "&quot;foo&gt;"
    end
    it "should store values in cache" do
      cust = Customer.create(:name=>'"foo>')
      cust.should_receive(:scaffold_name).and_return(cust.name)
      order = Order.new(:customer=>cust)
      cache = {}
      ret = helper.scaffold_value(order, :customer, true, cache)
      ret.should == %{<a href="/customer/show/#{cust.id}">&quot;foo&gt;</a>}
      cache["customer_id"][cust.id].should == cust.name
    end
    it "should use cached values" do
      cust = Customer.create(:name=>'"foo>')
      order = Order.new(:customer=>cust)
      cache = {"customer_id"=>{cust.id=>'"bang>'}}
      ret = helper.scaffold_value(order, :customer, true, cache)
      ret.should == %{<a href="/customer/show/#{cust.id}">&quot;bang&gt;</a>}
    end
    it "should offer download links for binary column" do
      get :foo
      cust = Customer.create
      ret = helper.scaffold_value(cust, :photo)
      ret.should =~ /^<a href="[^"]*\/download_column\/#{cust.id}\?column=photo">Herunterladen<\/a>$/
    end
    it "should create an image tag if binary column is an image" do
      get :foo
      cust = Customer.create
      cust.should_receive("photo_is_image?").and_return(true)
      ret = helper.scaffold_value(cust, :photo)
      ret.should =~ /<img.+src=".+\/download_column\/#{cust.id}\?column=photo"/
    end
    it "should offer download link if binary column is not an image" do
      get :foo
      cust = Customer.create
      cust.should_receive("photo_is_image?").and_return(false)
      ret = helper.scaffold_value(cust, :photo)
      ret.should =~ /^<a href="[^"]*\/download_column\/#{cust.id}\?column=photo">Herunterladen<\/a>$/
    end
  end
end
