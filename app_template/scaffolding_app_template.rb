gem 'scaffolding_esda', :git=>'https://gitorious.org/scaffolding_esda/scaffolding_esda.git', :branch=>'ror4.1'
gem "gettext_i18n_rails"
gem "jquery-ui-rails"
gem "jquery-turbolinks"
gem "handlebars_assets"
gem 'therubyracer',  platforms: :ruby

if Rails::VERSION::MAJOR == 4 and Rails::VERSION::MINOR < 2
  puts <<END
Your Rails version does not support after_bundle. 
Invoke ``rails generate esda:setup_scaffolding`` in your project to setup scaffolding correctly.
END
else
  after_bundle do
    # do not use spring as it does not know about bundled gems yet
    ENV["DISABLE_SPRING"]="1"
    generate "esda:setup_scaffolding"
  end
end
