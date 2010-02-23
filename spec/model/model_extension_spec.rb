require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','common_controllers.rb'))

def mock_column(name, primary=false)
  col = mock(ActiveRecord::ConnectionAdapters::PostgreSQLColumn)
  col.should_receive(:primary).and_return(primary)
  unless primary
    col.should_receive(:name).at_least(:once).and_return(name)
  end
  col
end

def mock_association(macro, name, klass, options={})
  assoc = mock(ActiveRecord::Reflection::AssociationReflection)
  assoc.should_receive(:macro).any_number_of_times.and_return(macro)
  assoc.should_receive(:options).any_number_of_times.and_return(options)
  assoc.should_receive(:klass).any_number_of_times.and_return(klass)
  assoc.stub!(:name).and_return(name)
  assoc
end

describe Esda::Scaffolding::Model::ClassMethods do
  after(:each) do 
    Customer.instance_variable_set("@scaffold_browse_fields", nil)
    Customer.scaffold_fields = nil
  end
  context "column_name_by_attribute method" do
    it "should return the attribute name as column if it is not an association" do
      Customer.should_receive(:reflect_on_association).with(:customer_number).and_return(nil)
      Customer.column_name_by_attribute(:customer_number).should == :customer_number
    end
    it "should return the foreign key for belongs_to associations" do
      assoc = mock(ActiveRecord::Reflection::AssociationReflection)
      assoc.should_receive(:options).and_return({})
      assoc.should_receive(:primary_key_name).and_return(:customer_id)
      Order.should_receive(:reflect_on_association).and_return(assoc)
      Order.column_name_by_attribute(:customer).should == :customer_id
    end
    it "should return the foreign key for belongs_to associations and respect the foreign_key option" do
      assoc = mock(ActiveRecord::Reflection::AssociationReflection)
      assoc.should_receive(:options).at_least(:once).and_return({:foreign_key=>'foo_id'})
      assoc.should_not_receive(:primary_key_name).and_return(:customer_id)
      Order.should_receive(:reflect_on_association).and_return(assoc)
      Order.column_name_by_attribute(:customer).should == 'foo_id'
    end
  end

  context "scaffold_fields method" do
    before do
      Customer.scaffold_fields = nil
    end
    it "should sort the columns" do
      scaffold_fields = Customer.scaffold_fields
      scaffold_fields.should == scaffold_fields.sort
    end
    it "should not include has_many associations" do
      test_name = Customer.reflect_on_all_associations.find_all{|assoc| assoc.macro==:has_many}.first.name.to_s
      Customer.scaffold_fields.should_not include test_name
    end
    it "should not include has_and_belongs_to_many associations" do
      class CustomerGroup
      end
      cg=mock(CustomerGroup)
      cg.stub!(:table_name).and_return("customer_groups")
      cg.stub!(:name).and_return("customer_group")
      cust_group = mock_association(:has_and_belongs_to_many, :customer_group, cg)
      Customer.should_receive(:reflect_on_all_associations).and_return([cust_group])
      pcol = mock_column("customer_id", true)
      any_col = mock_column("customer_number")

      Customer.should_receive(:columns).and_return([pcol, any_col])
      Customer.scaffold_fields.should == %w(customer_number)
    end
    it "should include belongs_to associations" do
      class CustomerGroup
      end
      cg=mock(CustomerGroup)
      cg.stub!(:table_name).and_return("customer_groups")
      cg.stub!(:name).and_return("customer_group")
      cust_group = mock_association(:belongs_to, :customer_group, cg)
      Customer.should_receive(:reflect_on_all_associations).and_return([cust_group])
      pcol = mock_column("customer_id", true)
      any_col = mock_column("customer_number")

      Customer.should_receive(:columns).and_return([pcol, any_col])
      Customer.scaffold_fields.should == %w(customer_group customer_number)
    end
    it "should include neither created_at, updated_at created_by not updated_by" do
      pcol = mock_column("customer_id", true)
      any_col = mock_column("customer_number")
      Customer.should_receive(:columns).and_return([pcol, any_col] + %w(created_at updated_at created_by updated_by).map{|c| mock_column(c)})
      Customer.scaffold_fields.should == %w(customer_number)
    end
    it "should not include the primary key" do
      pcol = mock_column("customer_id", true)
      any_col = mock_column("customer_number")
      Customer.should_receive(:columns).and_return([pcol, any_col])
      Customer.scaffold_fields.should == %w(customer_number)
    end
  end

  context "scaffold_browse_fields" do
    it "should return scaffold_fields if nothing else configured" do
      Customer.should_receive(:scaffold_fields).and_return(%w(a b))
      Customer.scaffold_browse_fields.should == %w(a b)
    end

    it "should return the contents of @scaffold_browse_fields if set" do
      Customer.instance_variable_set("@scaffold_browse_fields", %w(a b c))
      Customer.scaffold_browse_fields.should == %w(a b c)
    end
  end

  context "scaffold_no_browse_fields" do
    it "should return scaffold_fields without scaffold_browse_fields" do
      Customer.should_receive(:scaffold_fields).and_return(%w(a b c))
      Customer.should_receive(:scaffold_browse_fields).and_return(%w(a))
      Customer.scaffold_no_browse_fields.should == %w(b c)
    end
  end

  context "scaffold_fields=" do
    it "should store scaffold_fields" do
      testcolumns = %w(field_a field_b field_c)
      Customer.scaffold_fields = testcolumns
      Customer.scaffold_fields.should == testcolumns
    end
  end
end
