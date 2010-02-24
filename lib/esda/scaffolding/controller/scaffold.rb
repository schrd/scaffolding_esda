module Esda::Scaffolding::Controller
  module Scaffold
    protected
    def render_scaffold_tng(action, options={})
      @scaffold_singular_name = model_class.name
      @scaffold_plural_name = model_class.name.pluralize
      @scaffold_singular_object = @instance
      if self.respond_to?(:set_legacy_vars)
        set_legacy_vars
      end
      layout = request.xhr? ? false : 'esda'
      if Rails::VERSION::MAJOR == 1
        if template_exists?("#{self.class.controller_path}/#{action}")
          render(options.merge({:action=>action, :layout=>layout}))
        else
          render(options.merge({:file=>File.dirname(__FILE__) + "/../../../../scaffolds_tng/#{action}.rhtml", :layout=>layout}))
        end
      else
        begin
          render(options.merge({:action=>action, :layout=>layout}))
        rescue ActionView::MissingTemplate
          render(options.merge({:file=>File.dirname(__FILE__) + "/../../../../scaffolds_tng/#{action}.rhtml", :layout=>layout}))
        end
      end
    end
    @@scaffold_template_dir = "#{File.dirname(__FILE__)}/../../../../scaffolds_tng"
    # The location of the scaffold templates
    def scaffold_template_dir
      @scaffold_template_dir ||= @@scaffold_template_dir
    end

    # The methods that should be added by the scaffolding function by default
    def default_scaffold_methods
      @default_scaffold_methods ||= @@default_scaffold_methods
    end

    # Returns path to the given scaffold rhtml file
    def scaffold_path(template_name)
      File.join(scaffold_template_dir, template_name+'.rhtml')
    end
  end
  module ClassMethods
    def scaffold(model_id, options={})
      scaffold_tng(model_id, options)
      module_eval <<-"end_eval"
        helper :"Esda::Scaffolding::Helper::Legacy"
        protected
        def set_legacy_vars
          @#{model_id.to_s.underscore.singularize} = @instance
          @scaffold_class = model_class
        end
      end_eval
    end
    def scaffold_tng(model_id, options={})
      class_name = model_id.to_s.underscore.camelize
      params_name = model_id.to_s.underscore
      options.assert_valid_keys(:except, :only, :habtm)
      add_methods = options[:only] ? options[:only] : [:browse, :new, :edit, :show, :destroy]
      if add_methods.is_a?(Symbol)
        add_methods = [add_methods]
      end
      if options[:except]
        no_methods = options[:except]
        if no_methods.is_a?(Symbol)
          no_methods = [no_methods]
        end
        add_methods -= no_methods
      end
      include Esda::Scaffolding::Controller::Scaffold

      module_eval <<-"end_eval", __FILE__, __LINE__
        helper :"Esda::Scaffolding::Helper::FormScaffold"
        include Esda::Scaffolding::Controller::RecursiveCreator
        protected
        def model_class
          #{class_name}
        end
        def params_name
          :"#{params_name}"
        end
      end_eval
      if add_methods.include?(:browse)
        include Esda::Scaffolding::Controller::Browse
      end
      if add_methods.include?(:new)
        include Esda::Scaffolding::Controller::New
      end
      if add_methods.include?(:edit)
        include Esda::Scaffolding::Controller::Edit
      end
      if add_methods.include?(:show)
        include Esda::Scaffolding::Controller::Show
      end
      if add_methods.include?(:destroy)
        include Esda::Scaffolding::Controller::Destroy
      end
      if options[:habtm]
        if options[:habtm].is_a?(Symbol)
          options[:habtm] = [options[:habtm]]
        end
        include Esda::Scaffolding::Controller::Browse
        klass = class_name.constantize
        options[:habtm].each {|assoc_sym|
          assoc = klass.reflect_on_association(assoc_sym)
          next if assoc.nil?
          module_eval <<-"end_eval", __FILE__, __LINE__
            def edit_#{assoc.name}
              @instance = model_class.find(params[:id])
              @assoc = model_class.reflect_on_association(:#{assoc_sym})
              render_scaffold_tng('edit_habtm')
            end
            def browse_associated_#{assoc.name}
              @assoc = model_class.reflect_on_association(:#{assoc_sym})
              t = Time.now
              model = @assoc.klass
              conditions = ['1=1']
              condition_params = []

              params_part = (params[:search][model.name.underscore.to_sym] rescue nil)
              conditions, condition_params = build_conditions(model, params_part) if params_part
              conditions << "#\{model.table_name}.\#{model.primary_key} IN (SELECT \#{@assoc.association_foreign_key} from \#{@assoc.options[:join_table]} WHERE \#{@assoc.primary_key_name} = ?)"
              condition_params << params[:id]
              handle_browse_data(model, conditions, condition_params)
            end
            def browse_unassociated_#{assoc.name}
              @assoc = model_class.reflect_on_association(:#{assoc_sym})
              t = Time.now
              model = @assoc.klass
              conditions = ['1=1']
              condition_params = []

              params_part = (params[:search][model.name.underscore.to_sym] rescue nil)
              conditions, condition_params = build_conditions(model, params_part) if params_part
              conditions << "#\{model.table_name}.\#{model.primary_key} NOT IN (SELECT \#{@assoc.association_foreign_key} from \#{@assoc.options[:join_table]} WHERE \#{@assoc.primary_key_name} = ?)"
              condition_params << params[:id]
              handle_browse_data(model, conditions, condition_params)
            end
            def add_#{assoc.name}
              @instance = model_class.find(params[:id])
              @assoc_inst = model_class.reflect_on_association(:#{assoc_sym}).klass.find(params[:add])
              unless @instance.#{assoc.name}.include?(@assoc_inst)
                @instance.#{assoc.name} << @assoc_inst
              end
              render :inline=>'OK'
            end
            def del_#{assoc.name}
              @instance = model_class.find(params[:id])
              @assoc_inst = model_class.reflect_on_association(:#{assoc_sym}).klass.find(params[:del])
              if @instance.#{assoc.name}.include?(@assoc_inst)
                @instance.#{assoc.name}.delete(@assoc_inst)
              end
              render :inline=>'OK'
            end
          end_eval
        }
      end
    end
  end
end
ActionController::Base.extend(Esda::Scaffolding::Controller::ClassMethods)
