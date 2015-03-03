module Esda
class ScaffoldControllerGenerator < Rails::Generators::NamedBase
  def create_controller_file
    create_file "app/controllers/#{file_name}_controller.rb", <<-FILE
class #{class_name}Controller < ApplicationController
  scaffold :#{file_name}
end
    FILE
    route "scaffold_resource :#{file_name}"
  end
end
end
