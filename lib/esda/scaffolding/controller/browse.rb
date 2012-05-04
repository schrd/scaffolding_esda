# defines methods which are made available in a scaffolded controller
module Esda::Scaffolding::Controller::Browse
  include Esda::Scaffolding::Controller::ConditionalFinder
  def index
    browse
  end
  def browse
    @model = model_class
    @extra_params = ""
    if params.has_key?(:search)
      # only keep those parameters in extra_params that are not a visible column.
      # Parameters for visible columns are handled by header_spec functions
      # extra_params is appended to livegrid parameters for data retrieval
      hash = params[:search][@model.name.underscore.to_sym].dup.delete_if{|k,v| 
        not @model.scaffold_no_browse_columns.include?(k.to_s)
      }

      @extra_params = hash.map{|k,v| "search[#{@model.name.underscore}][#{k}]=#{URI.encode(v, /[^a-zA-Z0-9.,]/)}"}.join("&")
    end
    @extra_params = [@extra_params, "link=true"].compact.join("&")
    #expires_in 60.minutes
    render_scaffold_tng('browse')
  end
  # delivers data to the livegrid
  # data is returned in json format
  def browse_data
    t = Time.now
    model = model_class
    conditions = ['1=1']
    condition_params = []

    params_part = (params[:search][model.name.underscore.to_sym] rescue nil)
    conditions, condition_params = build_conditions(model, params_part) if params_part
    handle_browse_data(model, conditions, condition_params)
  end
  private
  def handle_browse_data(model, conditions, condition_params, browse_fields = nil)
    browse_fields = model.scaffold_browse_fields if browse_fields.nil?
    browse_include_field2_data = model.browse_include_fields2(browse_fields)
    @count = model.count(:conditions=>[conditions.join(" AND "), *condition_params], :include=>browse_include_field2_data[0])
    @link = false
    @link = true if params.has_key?(:link)
    if (not params[:sort].blank?) and params[:sort] =~ /(.+) (DESC|ASC)$/
      field = $1
      sort = $2
      if not browse_fields.include?(field)
        order = model.scaffold_select_order
      else
        ok = true
        if field =~ /\./
          includes, join_deps = browse_include_field2_data
          jd = ActiveRecord::Associations::ClassMethods::JoinDependency.new(model, includes, nil)
          dep = join_deps[ field.split('.')[0..-2].join('.') ]
          table = jd.joins[dep].aliased_table_name
          model_class2 = jd.joins[join_deps[ field.split('.')[0..-2].join('.') ]].reflection.klass
          field = model_class2.column_name_by_attribute(field.split('.').last)
          ok = false unless model_class2.column_names.include?(field)
        else
          table = model.table_name
          field = model.column_name_by_attribute(field)
          ok = false unless model.column_names.include?(field)
        end
        order = "#{table}.#{field} #{sort}" if ok
      end
    else
      order = model.scaffold_select_order
    end
    if model.respond_to?(:browse_find)
      @daten = model.browse_find(:conditions=>[conditions.join(" AND "), *condition_params], :offset=>params[:offset].to_i, :limit=>params[:limit].to_i, :order=>order)
    else
      @daten = model.find(:all, :include=>browse_include_field2_data[0], :conditions=>[conditions.join(" AND "), *condition_params], :offset=>params[:offset].to_i, :limit=>params[:limit].to_i, :order=>order)
    end
    #expires_in 20.seconds
    cache = {}
    @model = model
    t3 = Time.now
    json = render_to_string(:file=>scaffold_path('browse_data'), :layout=>false, :locals=>{:fields=>browse_fields})
    t4 = Time.now
    render :json=>json, :layout=>false
    t2 = Time.now
  end
  public
  # delivers the header specification for livegrid
  def headerspec
    @model = model_class
    #expires_in 1.days
    json = render_to_string(:inline=>"<%= header_fields_for(@model)%>")
    render :json=>json
  end
end
