module Esda
class ScaffoldControllerGenerator < Rails::Generators::NamedBase
  def create_controller_file
    create_file "app/controllers/#{file_name}_controller.rb", <<-FILE
class #{class_name}Controller < ApplicationController
  scaffold :#{file_name}
end
    FILE
    if File.readlines("config/routes.rb").grep(/include Esda::Scaffolding::Routing/).size == 0
      prepend_to_file "config/routes.rb" do
        "include Esda::Scaffolding::Routing\n# add a resourceful routes with actions necessary for scaffolding:\n#  scaffold_resource :product\n"
      end
    end

    route "scaffold_resource :#{file_name}"
  end
end
end
