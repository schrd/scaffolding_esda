module Esda::Scaffolding::Helper::ScaffoldHelper
  # Returns associated object's scaffold_name if column is an association, otherwise returns column value.
  # If column is a dotted name it descends this path using belongs_to associations. Example:
  #
  # class Order < ActiveRecord::Base
  #   belongs_to :customer
  #   has_many :order_positions
  # end
  # class OrderPosition < ActiveRecord::Base
  #   belongs_to :order
  # end
  #
  # It will display the customer_number field from customer if called like this:
  # scaffold_value(@order_position_instance, "order.customer.customer_number")
  #
  # Customization hooks:
  # For columns of type :binary
  #   #{column}_is_image? 
  #     * if true it will render an image tag. Image is linked to download action
  #     * if false (default) it will render a download link
  # For belongs_to associations
  #   see scaffold_column_options model class method
  # 
  #
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
          record_show(entry.send(column.to_s))
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
          elsif entry.column_for_attribute(column).type == :binary
            if entry.respond_to?("#{column}_is_image?".to_sym)
              image_tag(url_for(:action=>'download_column', :id=>entry.id, :column=>column))
            else
              link_to("Herunterladen", :action=>'download_column', :id=>entry.id, :column=>column)
            end
          else
            value
          end
        end
      end
    end
  end
  def header_fields_for(model_class)
    return self.send("#{model_class.name.underscore}_header_fields".to_sym, model_class) if respond_to?("#{model_class.name.underscore}_header_fields".to_sym)
    links = link_to(image_tag('filefind.png'), url_for(:action=>'show') + "/\#{#{model_class.primary_key}}", :title=>'Anzeigen') +
            link_to(image_tag('edit.png'), url_for(:action=>'edit') + "/\#{#{model_class.primary_key}}", :title=>'Bearbeiten') +
            link_to(image_tag('editcopy.png'), url_for(:action=>'new') + "?clone_from=\#{#{model_class.primary_key}}", :title=>'Kopieren') +
            link_to(image_tag('editdelete.png'), url_for(:action=>'destroy') + "/\#{#{model_class.primary_key}}", :title=>'Löschen', :onclick=>"return(confirm('\#{scaffold_name} wirklich löschen?'))") +
            has_many_links(model_class)
 		([['Verknüpfungen', '<a class="button" onclick="findLiveGridAround(this).grid.search();">Suchen</a>', nil, nil, links]] +
		model_class.scaffold_browse_fields.map{|f|
      [scaffold_field_name(model_class, f), 
        input_search(model_class, f).to_s, 
        f, 
        (model_class.scaffold_column_options(f.to_s)['search']['width'] rescue nil),
        column_template(model_class, f)]
		}).to_json
  end
  def has_many_links(model_class)
    associations = model_class.reflect_on_all_associations.find_all{|a| a.macro==:has_many and not a.options.has_key?(:through)}.sort_by{|a| a.name.to_s}
    content_tag('div',
      image_tag('2downarrow.png') +
      content_tag('div',
        content_tag('div', 
          content_tag('div',
            associations.map{|assoc|
              foreignkeyfield = (assoc.options.has_key?(:foreign_key) ?
                assoc.options[:foreign_key] :
                assoc.primary_key_name)
              content_tag('div',
                link_to(assoc.name.to_s.capitalize, 
                  url_for(:controller=>assoc.class_name.underscore, 
                    :action=>'browse') +  
                    "?search[#{assoc.class_name.underscore}][#{foreignkeyfield}]=\#{#{model_class.primary_key}}"
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
    if record.is_a?(ActiveRecord::Base)
      return record.class.scaffold_field_name(column)
    else
      return record.scaffold_field_name(column)
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
  def has_many_association_tab(assoc)
    content_tag('div', '',
      :extra_params=>"search[#{assoc.klass.name.underscore}][#{assoc.primary_key_name}]=#{@instance.id}",
      :header_url=>url_for(:controller=>"/"+assoc.klass.name.underscore, :action=>"headerspec"),
      :url=>url_for(:controller=>"/"+assoc.klass.name.underscore, :action=>"browse_data"),
      :class=>'livegridDeferred'
    ) +
    content_tag('div', '', :class=>'newdialog', 
      :title=>"#{h(assoc.klass.scaffold_model_name)} neu anlegen"
    ) +
    link_to(
      image_tag("filenew.png") + " #{h(assoc.klass.scaffold_model_name)} neu anlegen", 
      {
        :action=>'new', 
        :controller=>assoc.klass.name.underscore, 
        "#{assoc.klass.name.underscore}[#{assoc.primary_key_name}]"=>@instance.id, 
        :invisible_fields => [assoc.primary_key_name.to_s.sub(/_id$/, '')]
      },
      :class=>"newdialog") 
  end

  def column_template(model_class, field)
    mc = model_class
    assocs = field.split(".")[0...-1]
    while a=assocs.shift do
      mc = mc.reflect_on_association(a.to_sym).klass
    end
    custom_method = "#{mc.name.underscore}_#{field.split(".").last}_column_template"
    logger.debug(custom_method)
    if self.respond_to?(custom_method)
      self.send(custom_method, model_class, field)
    else
      assoc = mc.reflect_on_association(field.split(".").last.to_sym)
      if assoc
        id_field = (assocs.size == 0 ? assoc.primary_key_name : (assocs +  ['id']).join("."))
        link_to("\#{#{field}}", url_for(:action=>'show', :controller=>assoc.klass.name.underscore)+ "/\#{#{id_field}}")
      else
        "\#{#{field}}"
      end
    end
  end
  def column_templates(model_class)
    h = {}
    model_class.scaffold_browse_fields.each{|sbf|
      h[sbf] = column_template(model_class, sbf)
    }
    h
  end
end
