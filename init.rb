# Include hook code here

if Rails.version < "3"
require 'esda/scaffolding/model_extension'
require 'esda/scaffolding/helper/scaffold_helper'
require 'esda/scaffolding/helper/legacy_helper'
require 'esda/scaffolding/helper/table_indexed_position_helper'
require 'esda/scaffolding/browse.rb'
require 'esda/scaffolding/edit.rb'
require 'esda/scaffolding/new.rb'
require 'esda/scaffolding/show.rb'
require 'esda/scaffolding/destroy.rb'
require 'scaffolding_tng'
end
