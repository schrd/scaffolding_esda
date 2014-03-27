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
    if respond_to?("#{entry.class.name.underscore}_#{column}_value")
      return send("#{entry.class.name.underscore}_#{column}_value", entry, column, link, cache)
    end
    return "".html_safe if entry.nil?
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
        id = entry.send(reflection.foreign_key)
        value = nil
        if cache.is_a?(Hash) 
          cachekey = reflection.foreign_key
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
        return h(value.to_s) + content_tag('span', h(''), :class=>'inlineshow', :url=>url_for(:action=>'show', :controller=>"/"+reflection.class_name.underscore.to_s, :id=>id), :title=>reflection.class_name.humanize) if not link 
        return h("")
      end
    else
      value = entry.send(column).methods.include?('scaffold_name') ? entry.send(column).scaffold_name : entry.send(column)
      if value.class == FalseClass
        'Nein'.html_safe
      elsif value.class == TrueClass
        'Ja'.html_safe
      else
        silence_warnings do
          value = l(value) if value.is_a?(Date)
          if entry.column_for_attribute(column).type == :text
            content_tag("div", content_tag("pre", h(value)), :class=>"pre")
          elsif entry.column_for_attribute(column).type == :binary
            if entry.respond_to?("#{column}_is_image?".to_sym) and entry.send("#{column}_is_image?".to_sym)
              image_tag(url_for(:action=>'download_column', :id=>entry.id, :column=>column, :controller=>entry.class.name.underscore.to_s))
            else
              link_to("Herunterladen", :action=>'download_column', :id=>entry.id, :column=>column, :controller=>entry.class.name.underscore.to_s)
            end
          else
            h(value)
          end
        end
      end
    end
  end
  def editable_scaffold_value(entry, column, options={})
    options = {
      :form_url=>{:action=>'edit_field', :id=>entry.id, :field=>column, :controller=>entry.class.name.underscore},
      :update_url=>{:action=>'update_field', :id=>entry.id, :field=>column, :controller=>entry.class.name.underscore},
      :show_url=>{:action=>'show_field', :id=>entry.id, :field=>column, :controller=>entry.class.name.underscore},
      :link=>true,
      :editable=>true,
      :css_class=>"editable"
    }.merge(options)
    css_class = (options[:editable] ? options[:css_class] : nil)
    content_tag('div',
      scaffold_value(entry, column, options[:link], options[:cache]),
      :"data-form-url"=>url_for(options[:form_url]),
      :"data-update-url"=>url_for(options[:update_url]),
      :"data-show-url"=>url_for(options[:show_url]),
      :class=>css_class
    )
  end

  def header_fields_for(model_class)
    return self.send("#{model_class.name.underscore}_header_fields".to_sym, model_class) if respond_to?("#{model_class.name.underscore}_header_fields".to_sym)
    links = link_to(image_tag('filefind.png'), url_for(:action=>'show') + h("/{{#{model_class.primary_key}}}"), :title=>'Anzeigen') +
            link_to(image_tag('edit.png'), url_for(:action=>'edit') + h("/{{#{model_class.primary_key}}}"), :title=>'Bearbeiten') +
            link_to(image_tag('editcopy.png'), url_for(:action=>'new') + h("?clone_from={{#{model_class.primary_key}}}"), :title=>'Kopieren') +
            link_to(image_tag('editdelete.png'), url_for(:action=>'destroy') + h("/{{#{model_class.primary_key}}}"), :title=>'Löschen', :onclick=>"return(confirm('{{scaffold_name}} wirklich löschen?'))") +
            has_many_links(model_class)
 		([[h(_('Links')), '<a class="button searchbutton">Suchen</a>'.html_safe, nil, nil, links]] +
		model_class.scaffold_browse_fields.map{|f|
      [scaffold_field_name(model_class, f), 
        input_search(model_class, f).to_s, 
        f, 
        (model_class.scaffold_column_options(f.to_s)['search']['width'] rescue nil),
        column_template(model_class, f)]
		}).to_json.html_safe
  end
  def has_many_links(model_class)
    associations = model_class.reflect_on_all_associations.find_all{|a| a.macro==:has_many and not a.options.has_key?(:through)}.sort_by{|a| a.name.to_s}
    content_tag('div',
      image_tag('2downarrow.png') +
      content_tag('div',
        content_tag('div', 
          content_tag('div',
            associations.map{|assoc|
              foreignkeyfield = assoc.foreign_key
              content_tag('div',
                link_to(h(assoc.name.to_s.capitalize), 
                  url_for(:controller=>assoc.class_name.underscore, 
                    :action=>'browse'
                  ) + "?search[#{h(assoc.class_name.underscore)}][#{h(foreignkeyfield)}]={{#{h(model_class.primary_key)}}}".html_safe
                )
              )
            }.join("\n").html_safe
          )
        ),
        :class=>"associationslist"
      ),
      :class=>"hasmanyassociations"
    )
  end
  def scaffold_field_name(record, column)
    if record.is_a?(ActiveRecord::Base)
      return h(_(record.class.scaffold_field_name(column)))
    else
      return h(_(record.scaffold_field_name(column)))
    end
  end

  def feldhilfe(model, method)
    id = "#{model}_#{method}_help"
    #onclick = remote_function(:update=>id, :url=>{:action=>"hilfepopup", :controller=>"feldbeschreibung", :model=>model, :methode=>method, :sprache_id=>1})
    help = Feldbeschreibung.find_by_methode_and_model_and_sprache_id(method, model, 1).try(:beschreibung)
    content_tag('span', image_tag("help.png"), :title=>help)
  end
  def input_search(record_class, column, options = {})
    column_name = column
    record_name = record_class.name.underscore
    if column_name.to_s =~ /\./
      includes, join_deps = record_class.browse_include_fields2
      jd = ActiveRecord::Associations::JoinDependency.new(record_class, includes, [])
      dep = join_deps[ column_name.split('.')[0..-2].join('.') ]
      model_class2 = jd.join_parts[dep].reflection.klass
      field = model_class2.column_name_by_attribute(column_name.split('.').last)
      column = model_class2.columns_hash[field]
      param_column_name = column_name
    else
      model_class2 = record_class
      param_column_name = column
      field = column
      column = record_class.columns_hash[record_class.column_name_by_attribute(column)]
      param_column_name = column.name unless column.nil?
    end

    value = ((params[options[:param]][record_name.to_sym][param_column_name.to_sym] rescue params[:search][record_name.to_sym][param_column_name.to_sym]) rescue  nil)
    #logger.debug("Wert von #{record_name}.#{column.name}: " + value.inspect)
    prefix = (options.has_key?(:param) ? options[:param].to_s : "search")
    record_name = record_class.to_s.underscore
    if respond_to?("input_search_for_#{model_class2.name.underscore}_#{field}")
      return self.send("input_search_for_#{model_class2.name.underscore}_#{field}", record_name, param_column_name, prefix, value, options)
    end
    return if column.nil?
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
    tag('input', {"name"=>"#{prefix}[#{record_name}][#{column}]", 'id'=> "#{prefix}_#{record_name}_#{column}", 'value'=>value}.merge(size)).html_safe
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
        }.join(zusammen).html_safe

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
    content_tag("select", options.html_safe, hash)
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
    (from +
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
          }.merge(size))).html_safe
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
      :extra_params=>"search[#{assoc.klass.name.underscore}][#{assoc.foreign_key}]=#{@instance.id}",
      :header_url=>url_for(:controller=>"/"+assoc.klass.name.underscore, :action=>"headerspec"),
      :url=>url_for(:controller=>"/"+assoc.klass.name.underscore, :action=>"browse_data"),
      :class=>'livegridDeferred'
    ) +
    content_tag('div', '', :class=>'newdialog', 
      :title=>h(_("Create new %{model_name}" % {:model_name=>assoc.klass.scaffold_model_name}))
    ) +
    link_to(
      image_tag("filenew.png") + h(_("Create new %{model_name}" % {:model_name=>assoc.klass.scaffold_model_name})), 
      {
        :action=>'new', 
        :controller=>assoc.klass.name.underscore, 
        "#{assoc.klass.name.underscore}[#{assoc.foreign_key}]"=>@instance.id, 
        :invisible_fields => [assoc.foreign_key.to_s.sub(/_id$/, '')]
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
        id_field = field + ".id"
        link_to(h("{{#{field}.scaffold_name}}"), url_for(:action=>'show', :controller=>assoc.klass.name.underscore)+ h("/{{#{id_field}}}"))
      else
        h("{{#{field}}}")
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

  def header_above_tabs(instance)
    method_name = instance.class.name.underscore + "_header_above_tabs"
    if respond_to?(method_name.to_sym)
      self.send(method_name.to_sym, instance)
    end
  end

  def footer_below_tabs(instance)
    method_name = instance.class.name.underscore + "_footer_below_tabs"
    if respond_to?(method_name.to_sym)
      self.send(method_name.to_sym, instance)
    end
  end
end
