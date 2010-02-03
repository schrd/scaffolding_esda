require "common_models"
class CustomerController < ActionController::Base
  scaffold :customer
end

class OrderController < ActionController::Base
  scaffold :order
end

class OrderPositionController < ActionController::Base
  scaffold :order_position
end
