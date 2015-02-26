gem 'scaffolding_esda', :git=>'https://gitorious.org/scaffolding_esda/scaffolding_esda.git', :branch=>'ror4.1'
gem "gettext_i18n_rails"
gem "jquery-ui-rails"
gem "jquery-turbolinks"
gem "handlebars_assets"

generate(:model, "user", "name:string")
inject_into_class "app/models/user.rb", "User" do 
<<RUBY
  def self.current_user=(u)
    @current_user=u
  end
  def self.current_user
    @current_user
  end

  def has_privilege?(priv)
    true
  end
  def has_any_privilege?(priv)
    true
  end
RUBY
end

inject_into_class "app/controllers/application_controller.rb", "ApplicationController" do
<<RUBY
  before_filter :load_user

  helper :scaffold_menu
  layout 'application'

  protected
  def load_user
    User.current_user = User.first
  end
RUBY
end


prepend_to_file "config/routes.rb" do
  "include Esda::Scaffolding::Routing\n
# add a resourceful routes with actions necessary for scaffolding:\n#  scaffold_resource :product\n"
end
route "root 'scaffold_index#index'"

empty_directory 'locale'
initializer 'fast_gettext.rb', <<-RUBY
FastGettext.add_text_domain '#{@app_name}',:path=>'locale'
FastGettext.default_text_domain = '#{@app_name}'
FastGettext.default_available_locales = ['en']
RUBY


# configure assets

insert_into_file "app/assets/javascripts/application.js", :after=>/\/\/= require jquery$/ do 
<<END

//= require jquery.turbolinks

//= require jquery-ui
//= require handlebars

END
end
append_to_file "app/assets/javascripts/application.js" do
<<END
//= require scaffolding_esda
END
end

insert_into_file "app/assets/stylesheets/application.css", :before=>/ \*\// do
<<END
 *= require jquery-ui
 *= require scaffolding_esda
END
end

append_to_file "db/seeds.rb", <<-RUBY
User.create(name: "example user")
RUBY

create_file "app/controllers/user_controller.rb", <<-RUBY
class UserController < ApplicationController
  scaffold :user
end
RUBY
route "scaffold_resource :user"
