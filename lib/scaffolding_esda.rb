module Esda
  module Scaffolding
    module Helper
    end
    module Controller
    end
    module Rails
      class Engine < ::Rails::Engine
      end
    end
  end
end
require 'esda/scaffolding/model_extension'
require 'esda/scaffolding/controller/conditional_finder'
require 'esda/scaffolding/controller/recursive_creator'
require 'esda/scaffolding/helper/scaffold_helper'
require 'esda/scaffolding/helper/form_scaffold_helper'
require 'esda/scaffolding/helper/legacy_helper'
require 'esda/scaffolding/helper/table_indexed_position_helper'
require 'esda/scaffolding/controller/browse.rb'
require 'esda/scaffolding/controller/edit.rb'
require 'esda/scaffolding/controller/new.rb'
require 'esda/scaffolding/controller/show.rb'
require 'esda/scaffolding/controller/destroy.rb'
require "esda/scaffolding/controller/scaffold"
require "esda/scaffolding/access_token"
