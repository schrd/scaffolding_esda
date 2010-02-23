require "spec_helper"
require "common_models"
describe Esda::Scaffolding::Controller::ConditionalFinder do
  include Esda::Scaffolding::Controller::ConditionalFinder
  before(:each) do
    Customer.instance_variable_set("@scaffold_browse_fields", nil)
  end
  it "should search case insensitive on string columns with a left-bould like search" do
    conditions, condition_params = build_conditions(Customer, {:country=>'de'})
    conditions.should == ["1=1", "UPPER(customers.country) LIKE UPPER(?)"]
    condition_params.should == ["de%"]
  end
  it "should recursively descend along belongs_to associations for dot seperated attributes" do
    conditions, condition_params = build_conditions(OrderPosition, {:"order.customer.country"=>'de'})
    conditions.should == ["1=1", "UPPER(customers.country) LIKE UPPER(?)"]
    condition_params.should == ["de%"]
  end

  it "should generate range statements for date columns" do
    conditions, condition_params = build_conditions(Order, {:deliver_until=>{:to=>'31.12.2009'}})
    condition_params.should == [Date.new(2009,12,31)]
    conditions.should == ["1=1", "orders.deliver_until <= ?"]
    conditions, condition_params = build_conditions(Order, {:deliver_until=>{:from=>'31.12.2009'}})
    condition_params.should == [Date.new(2009,12,31)]
    conditions.should == ["1=1", "orders.deliver_until >= ?"]
  end

  it "should generate range conditions for numeric columns" do
    conditions, condition_params = build_conditions(Order, {:order_number=>{:to=>'42', :from=>'23'}})
    condition_params.should include 42
    condition_params.should include 23
    conditions.should include "orders.order_number <= ?"
    conditions.should include "orders.order_number >= ?"
  end

  it "should generate = conditions for numeric columns" do
    conditions, condition_params = build_conditions(Order, {:order_number=>'42'})
    condition_params.should include 42
    conditions.should include "orders.order_number = ?"
  end

  it "should accept selection lists for numeric columns" do
    conditions, condition_params = build_conditions(Order, {:order_number=>['23','42']})
    condition_params.should include [23,42]
    conditions.should include "orders.order_number IN (?)"
  end

  it "should accept iso decimal seperator for decimal columns" do
    conditions, condition_params = build_conditions(OrderPosition, {:quantity=>"1,2"})
    condition_params.should include 1.2
  end

  it "should ignore malformed decimal parameter values" do
    conditions, condition_params = build_conditions(OrderPosition, {:quantity=>"1#2a"})
    conditions.should_not include "order_positions.quantity = ?"
  end
  it "should ignore malformed integer parameter values" do
    conditions, condition_params = build_conditions(Order, {:order_number=>"1#2a"})
    conditions.should_not include "order.order_number = ?"
  end

end
