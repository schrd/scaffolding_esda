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

- implement a scaffold_name method in each model. The return value of this method is used whenever your your model instance is displayed, such as in displaying a belongs_to association
- add a @scaffold_browse_fiels variable. It should be a list that contains the fields shown for browsing. Default: all fields in the model
- add a @scaffold_fields variable. It should be a list that contains the fields shown in edit/show/new forms
- you might want to implement a <fieldname>_immutable? method. If it returns true, the field value cannot be changed in edit forms
