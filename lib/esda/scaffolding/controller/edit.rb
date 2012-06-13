# defines edit/update actions
module Esda::Scaffolding::Controller::Edit
  def edit
    begin
      @instance = model_class.find(params[:id])
      @options = {}
      @options[:fixed_fields] = params[:fixed_fields] if params.has_key?(:fixed_fields)
      @options[:invisible_fields] = params[:invisible_fields] if params.has_key?(:invisible_fields)
      @tab_associations = model_class.reflect_on_all_associations.find_all{|a| 
        a.macro==:has_many and not a.options.has_key?(:through)
      }.sort_by{|a| 
        a.name.to_s.humanize
      }
      if model_class.respond_to?(:inline_association)
        @inline_association = model_class.inline_association
        @tab_associations -= [@inline_association]
      else
        @inline_association = nil
      end
      if @instance.respond_to?(:extra_tab_links)
        @extra_tab_links = @instance.extra_tab_links
      else
        @extra_tab_links = []
      end
      @habtm_associations = model_class.reflect_on_all_associations.find_all{|a| 
        a.macro==:has_and_belongs_to_many
      }.sort_by{|a| 
        a.name.to_s.humanize
      }
      if params[:inline].to_i==1
        render :inline=>"<%= record_form(@instance) %>"
      else
        render_scaffold_tng "edit"
      end
    rescue ActiveRecord::RecordNotFound
      render :inline=>"Datensatz mit ID <%= params[:id].to_i %> nicht gefunden", :status=>404
    end
  end
  def update
    if not params.has_key?(params_name)
      return edit
    end
    begin
      @instance = model_class.find(params[:id])
      if model_class.locking_enabled?() and 
           params[params_name].has_key?(model_class.locking_column) and 
           params[params_name][model_class.locking_column].to_i < @instance.lock_version.to_i
        raise ActiveRecord::StaleObjectError, "Attempted to update a stale object"
      end
      @tab_associations = model_class.reflect_on_all_associations.find_all{|a| 
        a.macro==:has_many and not a.options.has_key?(:through)
      }.sort_by{|a| 
        a.name.to_s.humanize
      }
      if model_class.respond_to?(:inline_association)
        @inline_association = model_class.inline_association
        @tab_associations -= [@inline_association]
      else
        @inline_association = nil
      end
      @habtm_associations = model_class.reflect_on_all_associations.find_all{|a| 
        a.macro==:has_and_belongs_to_many
      }.sort_by{|a| 
        a.name.to_s.humanize
      }
      @instance, created_objects = recursively_update(@instance, params[params_name])
      @options = {}
      @options[:fixed_fields] = params[:fixed_fields] if params.has_key?(:fixed_fields)
      @options[:invisible_fields] = params[:invisible_fields] if params.has_key?(:invisible_fields)
      status=200
      begin
        model_class.transaction do
          recursively_save_created_objects(@instance, created_objects)
        end
        if params.has_key?(:redirect_to)
          flash[:notice] = "Datensatz gespeichert"
          return(redirect_to(params[:redirect_to]))
        end
        flash.now[:notice] = "Datensatz gespeichert"
      rescue Exception=>e
        flash.now[:error] = e
        @instance, created_objects = recursively_update(@instance, params[params_name])
        status=422
      end
      render_scaffold_tng "edit", :status=>status
    rescue ActiveRecord::RecordNotFound
      render :inline=>"Datensatz mit ID #{params[:id].to_i} nicht gefunden", :status=>404
    rescue ActiveRecord::StaleObjectError
      render :inline=>"Datensatz mit ID #{params[:id].to_i} nicht geändert. Daten wurden in der Zwischenzeit schon geändert", :status=>:conflict
    end
  end
  def list_association
    @assoc = model_class.reflect_on_association(params[:association].to_sym)
    @instance = model_class.find(params[:id])
    render :inline=>'<%= content_tag("div", "", 
                    :class=>"livegrid", 
                    :url=>url_for(:controller=>"/"+@assoc.klass.name.underscore, :action=>"browse_data"), 
                    :header_url=>url_for(:controller=>"/"+@assoc.klass.name.underscore, :action=>"headerspec"),
                    :extra_params=>"search[#{@assoc.klass.name.underscore}][#{@assoc.primary_key_name}]=#{@instance.id}") %>', 
                    :layout=>false
  end
end
