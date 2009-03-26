class ActionController::Base
  def self.scaffold(model_id, options={})
    scaffold_tng(model_id, options)
    module_eval <<-"end_eval"
      include Esda::Scaffolding::Helper::LegacyHelper
      helper :"Esda::Scaffolding::Helper::Legacy"
      def set_legacy_vars
        @#{model_id.to_s.underscore.singularize} = @instance
        @scaffold_class = model_class
      end
    end_eval
  end
  def self.scaffold_tng(model_id, options={})
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

    module_eval <<-"end_eval", __FILE__, __LINE__
      include Esda::Scaffolding::Helper::FormScaffoldHelper
      helper :"Esda::Scaffolding::Helper::FormScaffold"
      include RecursiveCreator
      def model_class
        #{class_name}
      end
      def params_name
        :"#{params_name}"
      end
    end_eval
    if add_methods.include?(:browse)
      #module_eval <<-"end_eval", __FILE__, __LINE__
        include Esda::Scaffolding::Browse
      #end_eval
    end
    if add_methods.include?(:new)
      #module_eval <<-"end_eval", __FILE__, __LINE__
        include Esda::Scaffolding::New
      #end_eval
    end
    if add_methods.include?(:edit)
      #module_eval <<-"end_eval", __FILE__, __LINE__
        include Esda::Scaffolding::Edit
      #end_eval
    end
    if add_methods.include?(:show)
      #module_eval <<-"end_eval", __FILE__, __LINE__
        include Esda::Scaffolding::Show
      #end_eval
    end
    if add_methods.include?(:destroy)
      include Esda::Scaffolding::Destroy
    end
  end

  def render_scaffold_tng(action, options={})
    @scaffold_singular_name = model_class.name
    @scaffold_plural_name = model_class.name.pluralize
    @scaffold_singular_object = @instance
    if self.respond_to?(:set_legacy_vars)
      set_legacy_vars
    end
    layout = request.xhr? ? false : 'esda'
    if template_exists?("#{self.class.controller_path}/#{action}")
      render(options.merge({:action=>action, :layout=>layout}))
    else
      render(options.merge({:file=>File.dirname(__FILE__) + "/../scaffolds_tng/#{action}.rhtml", :layout=>layout}))
    end
  end
  @@scaffold_template_dir = "#{File.dirname(__FILE__)}/../scaffolds_tng"
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
