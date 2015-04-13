Esda Scaffolding Extension for Ruby on Rails
============================================

This gem provides a user interface to database tables. It is an extract of an
inhouse ERP system developed at Esda.

Outstanding features are:

- it can handle millions of records in a sinlge table without pagination.
- it can handle lots of tables. At Esda it is used with hundreds of them in a single application.
- it offers nested creation of dependent records in a single transaction.
- it can handle media data stored in columns, such as pictures or pdf documents.
- it handles all relationships that rails models offer:
  - belongs_to
  - has_many
  - has_and_belongs_to_many
- data browsing: you can quickly navigate through relationships

Quickstart
==========

It is a good idea to use the application template as the extension has some dependencies:

    rails new my_scaffolding_app -m "https://raw.githubusercontent.com/schrd/scaffolding_esda/master/app_template/scaffolding_app_template.rb"
    cd my_scaffolding_app
    # if you are on rails 4.1 run   rails generate esda:setup_scaffolding
    rake db:migrate
    rake db:seed
    rails s
    # open http://localhost:3000/

- Create some models, edit the migrations to add not null constraints for attributes that cannot be empty. The extension can handle this.
- add relationships between the models
- create a controller for each model:


    class ProductController < ApplicationController
      scaffold :product
    end

- include include Esda::Scaffolding::Routing to config/routes.rb
- add a route: scaffold_resource :product
- you will probably want to modify the generated user model


Customize your models
=====================

scaffold_name
-------------

The return value of this method is used whenever your your model instance is displayed, such as in displaying a belongs_to association. If the model has a field called "name", its value is used as default, otherwise the value of to_s is used.

    class Address < ActiveRecord::Base
      def scaffold_name
        "#{self.name} from #{self.city}"
      end
    end

Customize fields used for browsing
----------------------------------

Set the @scaffold_browse_fiels variable. It should be a list that contains the fields shown for browsing. belongs_to associations can be traversed. Default: all fields in the model

    class Address < ActiveRecord::Base
      belongs_to :country

      @scaffold_browse_fields = %w(name street city zipcode country.name)
    end

Customize fields used in forms
------------------------------

Set the @scaffold_fields variable. It should be a list that contains the fields shown in edit/show/new forms

    class Address < ActiveRecord::Base
      @scaffold_fields = %w(name street city zipcode country)
    end

Set fields as readonly in forms
-------------------------------
Implement a <fieldname>_immutable? method. If it returns true, the field value cannot be changed in edit forms

    class Order < ActiveRecord::Base
      validates_presence_of :order_number

      def order_number_immutable?
        not self.new_record?
      end
    end

Computed columns in browsing
----------------------------
Any method of a model can be used as column for browsing.

    class Order < ActiveRecord::Base
      belongs_to :customer
      has_many :order_items
      @scaffold_browse_fields = self.scaffold_fields + ["value"]

      def value
        self.order_items.sum("quantity * price")
      end
    end

To make this column searchable a class method has to be implemented in the model and a helper is required to render the search widget. The model method must return a list of where conditions and a list of values which will be interpolated.

    class Order < ActiveRecord::Base
      belongs_to :customer
      has_many :order_items
      @scaffold_browse_fields = self.scaffold_fields + ["value"]

      def value
        self.order_items.sum("quantity * price")
      end

      # value will behave like a number field, so two parameters named "from" 
      # and "to" will be passed. These will be used to construct a subselect 
      # which sums up the value of order items that belong to an order
      def self.build_conditions_for_value(table, params_part, param_name)
        p_ge = params_part[param_name].try(:[], :from)
        p_le = params_part[param_name].try(:[], :to)

        conditions, condition_params = [], []
        unless p_ge.blank?
          conditions << "sum(quantity * price) >= ?"
          condition_params << BigDecimal.new(p_ge)
        end
        unless p_le.blank?
          conditions << "sum(quantity * price) <= ?"
          condition_params << BigDecimal.new(p_le)
        end
        return [], [] if conditions.size == 0
        subselect = "#{table}.id IN (SELECT order_id from order_items group by order_id HAVING #{conditions.join(' AND ')})"
        return [subselect], condition_params
      end
    end

Then add this helper:

    module OrderHelper
      def input_search_for_order_value(record_name, param_column_name, prefix, value, options)
        to_number_search_field_tag(record_name, param_column_name, prefix, value, options)
      end
    end
