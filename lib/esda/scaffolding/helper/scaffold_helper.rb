module Esda::Scaffolding::ScaffoldHelper
  # Returns associated object's scaffold_name if column is an association, otherwise returns column value.
  def scaffold_value(entry, column, link=true, cache=nil)
    return "" if entry.nil?
    if (column.to_s =~ /\./)
      assoc, rest = column.to_s.split('.', 2)
      return scaffold_value(entry.send(assoc), rest, link, cache)
    end
    reflection = entry.class.reflect_on_association(column.to_sym)
    if reflection and reflection.macro == :belongs_to
      column_options = entry.class.scaffold_column_options(column.to_s) || {}
      if column_options['render'] == :inline
        if (entry.send(column.to_s))
          render_component(:controller=>reflection.class_name.underscore.to_s, :action=>'showinline', :params=>{:column_name=>column.to_s, :idid =>(entry.send(column.to_s).id rescue nil)})
        end
      else
        id = entry.send(reflection.primary_key_name)
        value = nil
        if cache.is_a?(Hash) 
          cachekey = reflection.primary_key_name
          cache[cachekey] = {} unless cache.has_key?(cachekey) 
          if cache[cachekey].has_key?(id)
            value = cache[cachekey][id]
          else
            value = entry.send(column).methods.include?('scaffold_name') ? entry.send(column).scaffold_name : entry.send(column)
            cache[cachekey][id] = value
	  end
	else
          value = entry.send(column).methods.include?('scaffold_name') ? entry.send(column).scaffold_name : entry.send(column)
	end
	return link_to(h(value), :action=>'show', :controller=>reflection.class_name.underscore.to_s, :id=>id) if value and link
	return h(value.to_s) + content_tag('span', '', :class=>'inlineshow', :url=>url_for(:action=>'show', :controller=>"/"+reflection.class_name.underscore.to_s, :id=>id), :title=>reflection.class_name.humanize) if not link 
      end
    else
      value = entry.send(column).methods.include?('scaffold_name') ? entry.send(column).scaffold_name : entry.send(column)
      if value.class == FalseClass
        'Nein'
      elsif value.class == TrueClass
        'Ja'
      else
        silence_warnings do
          if entry.column_for_attribute(column).type == :text
            content_tag("div", value, :class=>"pre")
          else
            value
          end
        end
      end
    end
  end
  def header_fields_for(model_class)
 		([['Verknüpfungen', '<a class="button" onclick="findLiveGridAround(this).grid.search();">Suchen</a>']] +
		model_class.scaffold_browse_fields.map{|f|
      [scaffold_field_name(model_class, f), 
        input_search(model_class, f).to_s, 
        f, 
        (model_class.scaffold_column_options(f.to_s)['search']['width'] rescue nil)]
		}).to_json
  end
  def has_many_links(row)
    associations = row.class.reflect_on_all_associations.find_all{|a| a.macro==:has_many}.sort_by{|a| a.name.to_s}
    content_tag('div',
      '<img src="/images/2downarrow.png">' +
      content_tag('div',
        content_tag('div', 
          content_tag('div',
            associations.map{|assoc|
              foreignkeyfield = (assoc.options.has_key?(:foreign_key) ?
                assoc.options[:foreign_key] :
                assoc.primary_key_name)
              content_tag('div',
                link_to(assoc.name.to_s.capitalize, 
                  {:controller=>assoc.class_name.underscore, 
                    :action=>'browse', 
                    "search[#{assoc.class_name.underscore}][#{foreignkeyfield}]"=>row.id}
                )
              )
            }.join("\n")
          )
        ),
        :class=>"associationslist"
      ),
      :class=>"hasmanyassociations"
    )
  end
  def scaffold_field_name(record, column)
    begin
      if record.is_a?(ActiveRecord::Base)
      column_options = record.class.scaffold_column_options(column.to_s)
      else
        column_options = record.scaffold_column_options(column.to_s)
      end
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

  def feldhilfe(model, method)
    id = "#{model}_#{method}_help"
    onclick = remote_function(:update=>id, :url=>{:action=>"hilfepopup", :controller=>"feldbeschreibung", :model=>model, :methode=>method, :sprache_id=>1})
    content_tag('span', image_tag("help.png"), :onclick=>onclick) + content_tag("span", "", :id=>id)
  end
  def input_search(record_class, column, options = {})
    column_name = column
    if column_name.to_s =~ /\./
      includes, join_deps = record_class.browse_include_fields2
      jd = ActiveRecord::Associations::ClassMethods::JoinDependency.new(record_class, includes, nil)
      dep = join_deps[ column_name.split('.')[0..-2].join('.') ]
      model_class2 = jd.joins[dep].reflection.klass
      field = model_class2.column_name_by_attribute(column_name.split('.').last)
      column = model_class2.columns_hash[field]
      param_column_name = column_name
    else
      column = record_class.columns_hash[record_class.column_name_by_attribute(column)]
      return if column.nil?
      param_column_name = column.name
    end
    return if column.nil?
    record_name = record_class.to_s.underscore

    value = ((params[options[:param]][record_name.to_sym][column.name.to_sym] rescue params[:search][record_name.to_sym][column.name.to_sym]) rescue  nil)
    #logger.debug("Wert von #{record_name}.#{column.name}: " + value.inspect)
    prefix = (options.has_key?(:param) ? options[:param].to_s : "search")
    case column.type
    when :string, :text
      to_input_search_field_tag(record_name, param_column_name, prefix, value)
    when :date
      to_date_search_field_tag(record_name, param_column_name, prefix, value, options)
    when :boolean
      to_boolean_search_field_tag(record_name, param_column_name, prefix, value)
    when :password
            ""
    when :integer, :float, :decimal
      logger.debug("reflection: #{record_class.inspect} #{record_class.reflect_on_association(column_name.to_sym).inspect}")
      if (record_class.reflect_on_association(column_name.to_sym).macro == :belongs_to rescue false)
        to_belongs_to_search_field_tag(record_class, record_name, param_column_name, column_name, prefix, value, options)
      else
        to_number_search_field_tag(record_name, param_column_name, prefix, value, options)
      end
    end
  end

  def to_input_search_field_tag(record_name, column, prefix, value)
    logger.debug("record name: #{record_name}")
    begin
      size = { :size => record_name.classify.constantize.scaffold_column_options(column.to_s)['search']['size']}
    rescue
      size = {}
    end
    tag('input', {"name"=>"#{prefix}[#{record_name}][#{column}]", 'id'=> "#{prefix}_#{record_name}_#{column}", 'value'=>value}.merge(size))
  end
  def to_date_search_field_tag(record_name, column, prefix, value, options)
    zusammen = "<br/>"
    zusammen = " " if options.has_key?(:break) and options[:break]==false
        %w(from to).collect{ |kind|
          ret = tag('input', {"name"=>"#{prefix}[#{record_name}][#{column}][#{kind}]", 
                               'id'=> "#{prefix}_#{record_name}_#{column}_#{kind}", 
                               'value'=>(value[kind.to_sym] rescue nil),
             'class'=>"date_#{kind}",
                               'size'=>10}
                    )
        }.join(zusammen)

  end
  def to_boolean_search_field_tag(record_name, column, prefix, value)
    hash = {"name"=>"#{prefix}[#{record_name}][#{column}]"}
    def checked(test, val)
      return (test==val ? {"selected"=>"selected"} : {})
    end
    options = ""
    options += content_tag("option", "egal", {"value"=>''})
    options += content_tag("option", "Ja", {"value"=>'true'}.merge(checked(value, 'true')))
    options += content_tag("option", "Nein", {"value"=>'false'}.merge(checked(value, 'false')))
    content_tag("select", options, hash)
  end
  def to_number_search_field_tag(record_name, column, prefix, value, options)
    from = ""
    to = ""
    if options.has_key?(:from)
      from = options[:from]
    end
    if options.has_key?(:to)
      to = options[:to]
    end
    begin
      size = { :size => record_name.classify.constantize.scaffold_column_options(column.to_s)['search']['size']}
    rescue
      size = { :size=>5 }
    end
    zusammen = "<br />"
    zusammen = " " if options.has_key?(:break) and options[:break]==false
    from +
      tag('input', {"name"=>"#{prefix}[#{record_name}][#{column}][from]", 
                      'id'=> "#{prefix}_#{record_name}_#{column}_from", 
          'value'=>(value[:from] rescue nil),
          'class'=>'number_from'
          }.merge(size)) + 
    zusammen +
    to +
      tag('input', {"name"=>"#{prefix}[#{record_name}][#{column}][to]", 
                      'id'=> "#{prefix}_#{record_name}_#{column}_to", 
          'value'=>(value[:to] rescue nil),
          'class'=>'number_to',
          }.merge(size)) 
  end
  def to_belongs_to_search_field_tag(record_class, record_name, column, column_name, prefix, value, options)
    desc = (record_class.reflect_on_association(column_name.to_sym).klass.find(value).scaffold_name rescue nil)
    if (options[:display] == :all rescue false)
      myclass = record_class.reflect_on_association(column_name.to_sym).klass
      select_tag "#{prefix}[#{record_name}][#{column}]", 
        options_for_select([["egal", ""]] + 
          myclass.find(:all, :order => myclass.scaffold_select_order).collect {|elem| [elem.scaffold_name, elem.id]}
        )
          elsif value and desc
            options  = content_tag('option', desc, {'value'=>value})
            options += content_tag('option', "Egal", {'value'=>''})
            content_tag('select', options, 
        {"name" => "#{prefix}[#{record_name}][#{column}]", 
         'id'   => "#{prefix}_#{record_name}_#{column}", 'value'=>value})
    end
  end
end
