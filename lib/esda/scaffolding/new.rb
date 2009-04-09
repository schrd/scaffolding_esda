# defines scaffold methods for creating new instances
module Esda::Scaffolding::New
  def new
    p = params
    if not params[:name_prefix].blank?
      elems = params[:name_prefix].split(/[\[\]]/).find_all{|e| not e.blank?}
      while (e=elems.shift && p) do
        if p[e]
          p = p[e]
        else
          p = nil
        end
      end
    else
      p = params[params_name]
    end
    if params.has_key?(:clone_from)
      @clone = model_class.find(params[:clone_from])
    end
    @instance, created_objects = recursively_create(model_class, p, @clone)
    @options = {:hide_validation_errors=>true}
    @options[:fixed_fields] = params[:fixed_fields] if params.has_key?(:fixed_fields)
    @options[:invisible_fields] = params[:invisible_fields] if params.has_key?(:invisible_fields)
    if params[:inline].to_i == 1
      render :inline=>"<fieldset><legend><%= h @instance.class.scaffold_model_name %> neu anlegen</legend><%= record_form(@instance, @options.merge({:name_prefix=>params[:name_prefix]})) %></fieldset>", :layout=>false
    else
      render_scaffold_tng "new"
    end
  end
  def create
    @instance, created_objects = recursively_create(model_class, params[params_name])
    begin
      model_class.transaction do
        recursively_save_created_objects(@instance, created_objects)
      end
      # @instance.save!
      flash[:notice] = "Datensatz gespeichert"
      if params.has_key?(:redirect_to)
        return(redirect_to(params[:redirect_to]))
      end
      redirect_to :action=>'edit', :id=>@instance.id
    rescue Exception=>e
      flash.now[:error] = "Datensatz nicht gespeichert: #{e} #{e.backtrace.join("<br/>")}" unless e.is_a?(ActiveRecord::RecordInvalid)
      flash.now[:error] = "Datensatz nicht gespeichert: #{e}" if e.is_a?(ActiveRecord::RecordInvalid)
      # recreate objects, as they might loose their new_record? state
      @instance, created_objects = recursively_create(model_class, params[params_name])
      @options = {}
      @options[:fixed_fields] = params[:fixed_fields] if params.has_key?(:fixed_fields)
      @options[:invisible_fields] = params[:invisible_fields] if params.has_key?(:invisible_fields)
      render_scaffold_tng "new", :status=>422
    end
  end
end
