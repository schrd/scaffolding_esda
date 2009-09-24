require File.dirname(__FILE__) + '/test_helper.rb' 

class ModelTest < Test::Unit::TestCase
  load_schema

  def test_schema_has_loaded_correctly 
    assert_equal [], Product.all 
    assert_equal [], ProductClass.all 
    assert_equal [], Tag.all 
  end 

  def test_model_extensions
    assert_equal "Product", Product.human_name
    assert_equal Product.human_name.pluralize, Product.scaffold_model_plural_name
    assert_equal %w(comment product_class sku), Product.scaffold_fields
    assert (not Product.scaffold_fields.include?(Product.primary_key))
  end
end
