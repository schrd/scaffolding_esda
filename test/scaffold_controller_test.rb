require File.dirname(__FILE__) + '/test_helper.rb'
require 'action_controller/test_process' 
class ScaffoldControllerTest < ActionController::TestCase
  tests ProductController
  def test_crud
    get :index
    assert_response :success
    get :new
    assert_response :success
    assert_tag :input, :attributes=>{:class=>"string notnull", :name=>"product[sku]"}
    assert_tag :input, :attributes=>{:class=>"string", :name=>"product[comment]"}

    post :create, :product=>{:comment=>'foo'}
    assert_response(422)
    assert !flash.empty?
    assert_not_nil flash[:error]

    post :create, :product=>{:comment=>"foo", :sku=>"bar"}
    assert_response :redirect
    assert !flash.empty?
    assert_not_nil flash[:notice]
    p1 = Product.find_by_sku("bar")
    assert p1

    post :create, :product=>{:comment=>"foo", :sku=>"bar2", :product_class=>{:name=>'firstclass'}}
    assert_response :redirect
    assert !flash.empty?
    assert_not_nil flash[:notice]
    p2 = Product.find_by_sku("bar2")
    assert p2
    assert p2.product_class

    post :update, {:id=>p2.id, :product=>{:comment=>"", :sku=>"bar3"}}
    assert_response :success
    p2.reload
    assert_equal p2.sku, "bar3"
    #assert_empty p2.comment
    assert p2.product_class

    pc_old = p2.product_class
    post :update, {:id=>p2.id, :product=>{:comment=>"", :sku=>"bar3", :product_class=>{:name=>'secondclass'}}}
    assert_response :success
    p2.reload
    assert_not_equal pc_old, p2.product_class
    assert_equal p2.product_class.name, "secondclass"
    assert_equal ProductClass.count, 2

    post :destroy, :id=>p2.id
    assert_response :success
    assert_nil Product.find_by_sku("bar3")
  end
end
