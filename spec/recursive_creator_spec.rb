require "spec_helper"
require "common_models"

describe RecursiveCreator do
  include RecursiveCreator

  it "should create simple instances" do
    params = {:city=>"xyz"}
    inst, created_objects = recursively_create(Customer, params)
    inst.class.should == Customer
    inst.should be_valid
    inst.should be_new_record
    created_objects.size.should == 0
    inst.city.should == params[:city]
  end
  it "should update simple instances" do
    params = {:city=>"xyz"}
    cust = Customer.create!(params)
    params[:city] = "xyz2"
    inst, created_objects = recursively_update(cust, params)
    inst.should be_valid
    inst.city.should == params[:city]
  end
  it "should create dependant instances" do
    params = {:deliver_until=>'2009-12-31', :order_number=>1234, :customer=>{:customer_number=>12345, :city=>"xyz", :name=>"Foobar, inc."}}
    inst, created_objects = recursively_create(Order, params)
    inst.class.should == Order
    inst.should be_valid
    created_objects.class.should == Hash
    created_objects[:customer].first.class.should == Customer
    created_objects[:customer].first.should be_valid
    created_objects[:customer].first.should be_new_record
  end
  it "should update instance and create dependant instances" do
    params = {:deliver_until=>'2009-12-31', :order_number=>1234, :customer=>{:customer_number=>12345, :city=>"xyz", :name=>"Foobar, inc."}}
    inst, created_objects = recursively_create(Order, params)
    inst.class.should == Order
    inst.should be_valid
    created_objects.class.should == Hash
    created_objects[:customer].first.class.should == Customer
    created_objects[:customer].first.should be_valid
    recursively_save_created_objects(inst, created_objects)
    params[:order_number] = 2345
    params[:customer_id] = inst.customer_id
    params[:customer] = {:customer_number=>23456, :city=>'other city', :name=>'any other company'}
    updated_inst, created_objects = recursively_update(inst, params)
    updated_inst.should_not be_new_record
    recursively_save_created_objects(updated_inst, created_objects)
    updated_inst.reload
    updated_inst.order_number.should == params[:order_number]
    updated_inst.customer_id.should_not == params[:customer_id]
    updated_inst.customer.customer_number.should == params[:customer][:customer_number]
    updated_inst.customer.city.should == params[:customer][:city]
  end
end
