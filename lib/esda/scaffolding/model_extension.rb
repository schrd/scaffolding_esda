module Esda::Scaffolding::Model
  def self.included(base)
    base.extend(ClassMethods)
  end

  def to_fixture(filter_assocs_on=nil)
    relevant_habtm_associations = self.class.fixture_relevant_habtm_associations
    "#{fixture_name}:\n" +
      self.class.columns.find_all{|col|
        not col.primary
      }.map{|col|
        assoc = self.class.reflect_on_all_associations.find{|assoc| assoc.macro==:belongs_to and assoc.primary_key_name==col.name.to_s}
        if assoc
          val = self.send(assoc.name)
          val = val.fixture_name if val
          colname = assoc.name
        else
          colname = col.name
          val = self.attributes[col.name.to_s]
          #val = '""' if val == ""
          if val.is_a?(String)
            #val = "|-\n    " + val.split(/\r?\n/).join("\n    ") + "\n"
            val = val.to_yaml[4..-2].gsub(/\n/, "\n    ")
          end
        end
        "  #{colname}: #{val}"
    }.join("\n") + "\n" +
    relevant_habtm_associations.map{|assoc|
      restricted_assoc_instances = nil
      restricted_assoc_instances = filter_assocs_on.find_all{|inst| inst.class == assoc.klass} unless filter_assocs_on.nil?
      if restricted_assoc_instances
        assoc.klass.send(:with_scope, :find=>{:conditions=>["#{assoc.table_name}.#{assoc.klass.primary_key} IN (?)", restricted_assoc_instances.map{|inst| inst.id}]}) do
          "  #{assoc.name}: #{self.send(assoc.name).map{|inst| inst.fixture_name}.join(', ')}"
        end
      else
        "  #{assoc.name}: #{self.send(assoc.name).map{|inst| inst.fixture_name}.join(', ')}"
      end
    }.join("\n") + "\n"  
  end
  def fixture_name
    id
  end

  def differing_fields(comp)
    raise ArgumentError unless comp.class == self.class
    self.class.scaffold_fields.find_all{|f|
      begin
        self.send(f) != comp.send(f)
      rescue ActiveRecord::MissingAttributeError
        false
      end
    }
  end

  # all methods of this module are added to ActiveRecord::Base
  module ClassMethods
    attr_accessor :scaffold_select_order
    attr_accessor :scaffold_select_include
    def all_models
      Dir["#{RAILS_ROOT}/app/models/*.rb"].collect{|file|File.basename(file).sub(/\.rb$/, '')}.sort.reject{|model| (! model.camelize.constantize.ancestors.include?(self)) rescue true}
    end
    def scaffold_fields
      return @scaffold_fields if @scaffold_fields
      @scaffold_fields = columns.reject{|c| c.primary || c.name =~ /_count$/ || c.name == inheritance_column || c.name =~ /^lock_version$/ || c.name =~ /^(created|updated)_(at|by)$/ }.collect{|c| c.name}
      reflect_on_all_associations.each do |reflection|
        next unless reflection.macro == :belongs_to
        @scaffold_fields.delete((reflection.options[:foreign_key] || reflection.klass.table_name.classify.foreign_key).to_s)
        @scaffold_fields.push(reflection.name.to_s)
      end
      @scaffold_fields.sort!
      @scaffold_fields
    end

    def scaffold_fields=(fields)
      @scaffold_fields = fields
    end

    # +scaffold_browse_fields+ lists all fields which are show in an inline browser
    # You can use field names as well as names of +belongs_to+ associations as well 
    # as fields of associated instances. 
    #
    # It works like this:
    #   
    #   class Model < ActiveRecord::Base
    #     belongs_to :other_model
    #     @scaffold_browse_fields = %w(field1 field2 other_model.fieldA other_model.fieldB field3)
    #   end
    #
    # It can be nested to any depth
    def scaffold_browse_fields
      return @scaffold_browse_fields if @scaffold_browse_fields
      return scaffold_fields
    end
    def browse_include_fields
      @browse_include_fields ||= self.scaffold_browse_fields.map{|sf| 
        self.reflect_on_association(sf.to_sym)
      }.compact.find_all{|assoc| 
        assoc.macro==:belongs_to
      }.map{|a| a.name}
    end

    def scaffold_show_fields
      return @scaffold_show_fields if @scaffold_show_fields
      return scaffold_fields
    end
    # This method is needed for determining table name aliases by ActiveRecord Join Dependencies
    # it looks though the scaffold_browse fields and generates an include parameter for 
    # ActiveRecord::Base.find
    #
    # It also generates an index hash for ActiveRecords JoinDependency logic.
    # The Joindependency is needed for generating the correct table name for
    # the conditions parameter. It is used by the ConditionalFinder module
    def browse_include_fields2(fields = nil)
      includes = []
      join_deps = [self.name.to_sym]
      index = {}
      fields = scaffold_browse_fields if fields.nil?
      elements = fields.find_all{|f| f.to_s =~ /\./}.map{|f| f.split('.')[0..-2].map{|f| f.to_sym}}
      @hierarchize_counter = 0
      elements.sort_by(&:to_s).each{|e|
      hierarchize_fields!(includes, join_deps, e, e, index)
      }
      return includes, index
    end

    def scaffold_field_name(column)
      begin
        column_options = self.scaffold_column_options(column.to_s)
      rescue
        column_options = {}
      end
      if column_options.nil?
        column_options = {}
      end

      if column_options['title']
        column_options['title']
      else
        column.to_s.humanize
      end
    end
    private
    def hierarchize_fields!(includes, join_dependency_order, elements, all_elements, index)
      hash = includes.find{|e| e.keys.include?(elements[0])}
      if hash.nil?
        hash={elements[0] => []}
        includes << hash
        join_dependency_order << elements[0]
        @hierarchize_counter += 1
        index[all_elements.map{|e| e.to_s}.join('.')] = @hierarchize_counter
      end
      if elements.size > 1
        hierarchize_fields!(hash[elements[0]], join_dependency_order, elements[1..-1], all_elements, index)
      end
    end
    public

    def column_name_by_attribute(name)
      reflection = reflect_on_association(name.to_sym)
      if reflection
        return reflection.options[:foreign_key] if reflection.options[:foreign_key]
        return reflection.primary_key_name
      else
        return name
      end
    end

    # computes all fields which are scaffolded fopr forms but not for lists
    def scaffold_no_browse_fields
      scaffold_fields - scaffold_browse_fields
    end
    # does the same as +scaffold_no_browse_fields+ but maps each field to its appropriate database column
    def scaffold_no_browse_columns
      scaffold_no_browse_fields.map{|f| column_name_by_attribute(f.to_sym).to_s}.uniq
    end
    def scaffold_column_options(column_name)
      @scaffold_column_options_hash ||= scaffold_column_options_hash
      @scaffold_column_options_hash[column_name]
    end
    def scaffold_column_options_hash
      @scaffold_column_options_hash ||= {}
    end
    # gives the display name of the model in singular form
    # implement this in your model if you wish a different name for your model in scaffolded forms
    def scaffold_model_name
      name.humanize
    end
    # gives the display name of the model in plural form
    def scaffold_model_plural_name
      scaffold_model_name.pluralize
    end
      # Returns the scaffolded table class for a given scaffold type.
      def scaffold_table_class(type)
        @scaffold_table_classes ||= {:form=>'formtable', :list=>'sortable', :show=>'sortable'}
        @scaffold_table_classes[type]
      end
    def fixture_relevant_habtm_associations
      self.reflect_on_all_associations.find_all{|assoc| 
        assoc.macro==:has_and_belongs_to_many
      }.find_all{|assoc| 
        assoc.klass.name < self.class.name
      }
    end
  end
end
ActiveRecord::Base.send(:include, Esda::Scaffolding::Model)
