module Esda
  module Scaffolding
    module Helper
    end
    module Controller
      mattr_accessor :scaffold_layout
      def self.scaffold_layout
        if @@scaffold_layout
          return @@scaffold_layout
        else
          return 'esda'
        end
      end
      def self.can_use_window_functions?
        # querying AR is done only once
        if @window_functions_initialized
          return @can_use_window_functions
        else
          begin
            @window_functions_initialized = true
            if ActiveRecord::Base.configurations[Rails.env]["adapter"]=="postgresql"
              @can_use_window_functions = true
            else
              @can_use_window_functions = false
            end
            return @can_use_window_functions
          rescue
            @can_use_window_functions = false
            return false
          end
        end
      end
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
require "esda/scaffolding/routing"
