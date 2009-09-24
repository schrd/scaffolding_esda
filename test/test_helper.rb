ENV['RAILS_ENV'] = 'test' 
ENV['RAILS_ROOT'] ||= File.dirname(__FILE__) + '/../../../..' 
require 'test/unit' 
require File.expand_path(File.join(ENV['RAILS_ROOT'], 'config/environment.rb')) 

def load_schema 
  config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))  
  ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")  
  db_adapter = ENV['DB'] 
  # no db passed, try one of these fine config-free DBs before bombing.  
  db_adapter ||= begin 
                   require 'rubygems'  
                   require 'sqlite'  
                   'sqlite'  
                 rescue MissingSourceFile 
                   begin 
                     require 'sqlite3'  
                     'sqlite3'  
                   rescue MissingSourceFile 
                   end  
                 end  
  if db_adapter.nil? 
    raise "No DB Adapter selected. Pass the DB= option to pick one, or install Sqlite or Sqlite3."  
  end  
  ActiveRecord::Base.establish_connection(config[db_adapter])  
  load(File.dirname(__FILE__) + "/schema.rb")  
  require File.dirname(__FILE__) + '/../init.rb' 
end 
  class Product < ActiveRecord::Base
    belongs_to :product_class
    has_and_belongs_to_many :tags

    validates_presence_of :sku
    validates_uniqueness_of :sku
  end

  class Tag < ActiveRecord::Base
    has_and_belongs_to_many :products
  end

  class ProductClass < ActiveRecord::Base
    has_many :products
  end

  class ProductController < ActionController::Base
    scaffold :product
    def rescue_action(e) raise e end
  end
  class TagController < ActionController::Base
    scaffold :tag
  end
  class ProductClassController < ActionController::Base
    scaffold :product_class
  end
