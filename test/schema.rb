ActiveRecord::Schema.define(:version => 0) do
  begin
    drop_table :products
    drop_table :product_classes
    drop_table :tags
    drop_table :products_tags
    drop_table :schema_migrations
  rescue 
  end
  create_table :products, :force => true do |t| 
    t.string :sku, :null=>false
    t.string :comment
    t.references :product_class
    t.timestamps
  end
  create_table :product_classes, :force=>true do |t|
    t.string :name, :null=>false
    t.timestamps
  end
  create_table :tags, :force=>true do |t|
    t.string :name, :null=>false
    t.timestamps
  end
  create_table :products_tags, :force=>true, :id=>false do |t|
    t.references :product
    t.references :tag
  end
end
