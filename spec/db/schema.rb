ActiveRecord::Schema.define(:version => 0) do
  # create_table :chickens, :force => true do |t|
  #   t.column :name, :string
  #   t.column :age, :integer
  # end
  create_table :customers, :force=>true do |t|
    t.integer :customer_number
    t.string :name
    t.string :street
    t.string :city
    t.string :country
    t.string :zip_code
    t.binary :photo
  end
  create_table :orders, :force=>true do |t|
    t.integer :order_number
    t.date :deliver_until
    t.references :customer, :null=>false
  end
  create_table :order_positions, :force=>true do |t|
    t.references :order, :null=>false
    t.string :sku
    t.decimal :quantity
  end
end
