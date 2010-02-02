class Customer < ActiveRecord::Base
  has_many :orders
end

class Order < ActiveRecord::Base
  belongs_to :customer
  has_many :order_positions
end

class OrderPosition < ActiveRecord::Base
  belongs_to :order
  scaffold_browse_fields << "order.customer.country"
end
