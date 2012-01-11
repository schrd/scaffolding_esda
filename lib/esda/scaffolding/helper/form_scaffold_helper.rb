module Esda::Scaffolding::Helper::FormScaffoldHelper
  include Esda::Scaffolding::Helper::ScaffoldHelper
  include Esda::Scaffolding::Controller::ConditionalFinder

  # scaffold a record instance for show
  # valid options are:
  # * <tt>:name_prefix</tt>  a query string prefix that is passed to the +html_name+ method
  # * <tt>:invisible_fields</tt> lists fields which are not displayed
  # * <tt>:timestamps</tt> shows created/updated_by/at fields if set to true
  def record_show(record, options={})
    if respond_to?("#{record.class.name.underscore}_record_show")
      return send("#{record.class.name.underscore}_record_show", record, options)
    else
      model = record.class
      fields = record.class.scaffold_show_fields
      name_prefix = options[:name_prefix] # nil default
      fixed_fields = options[:fixed_fields] || []
      invisible_fields = options[:invisible_fields] || []
      fields -= invisible_fields
      timestamps = h("")
      if options[:timestamps]
        user_text = []
        if record.respond_to?(:updated_by)
          if record.updated_by.is_a?(User)
            user_text << h(record.updated_by.login)
          elsif record.updated_by.is_a?(Numeric)
            user_text << h(User.find(record.updated_by).login)
          end
        end
        if record.respond_to?(:updated_at) and not record.updated_at.nil?
          user_text << h(record.updated_at.strftime("%d.%m.%Y %H:%M:%S"))
        end
        if user_text.length == 0
          if record.respond_to?(:created_by)
            if record.created_by.is_a?(User)
              user_text << h(record.created_by.login)
            elsif record.created_by.is_a?(Numeric)
              user_text << h(User.find(record.created_by).login)
            end
          end
          if record.respond_to?(:created_at) and not record.created_at.nil?
            user_text << h(record.created_at.strftime("%d.%m.%Y %H:%M:%S"))
          end
        end
        timestamps << content_tag('tr', 
            content_tag('th', h(_('Last changed'))) +
            content_tag('td', user_text.join(" ").html_safe)
          )
      end
      content_tag('div',
        content_tag('table',
          fields.map{|f|
            field_element = scaffold_value(record, f, false)
            content_tag('tr',
              content_tag('th', scaffold_field_name(record, f) + ":") +
              content_tag('td', field_element)
            )
          }.join().html_safe + timestamps,
          :class=>"record-show"
        ) 
      ) 
    end
  end
  # scaffold a record instance for edit
  # valid options are:
  # * <tt>:name_prefix</tt>  a query string prefix that is passed to the +html_name+ method
  # * <tt>:fixed_fields</tt> lists fields which are immutable
  # * <tt>:invisible_fields</tt> lists fields which are not displayed
  #
  # Fields are chosen from the +scaffold_fields+ class method of the record
  def record_form(record, options={})
    if respond_to?("#{record.class.name.underscore}_record_form")
      return send("#{record.class.name.underscore}_record_form", record, options)
    else
      model = record.class
      fields = record.class.scaffold_fields
      logger.debug("form options: #{options.inspect}")
      fixed_fields = options[:fixed_fields] || []
      invisible_fields = options[:invisible_fields] || []
      invisible_fields = invisible_fields.find_all{|invf| fields.include?(invf)}
      fields -= invisible_fields
      record_form_table(record, options, fields, fixed_fields, invisible_fields)
    end
  end
  def record_form_table(record, options, fields, fixed_fields, invisible_fields)
    name_prefix = options[:name_prefix] # nil default
    model = record.class
    lock_field = ""
    if model.locking_enabled?() and not record.new_record?
      lock_field = hidden_field_tag(html_name(model, model.locking_column, name_prefix), record.send(model.locking_column))
    end
    content_tag('div',
      content_tag('table',
        fields.map{|f|
          field_element = nil
          if fixed_fields.include?(f) or (record.respond_to?("#{f}_immutable?") and record.send("#{f}_immutable?"))
            colname = model.column_name_by_attribute(f)
            val = record.send(colname)
            if val.class==TrueClass
              val = 't'
            elsif val.class == FalseClass
              val = 'f'
            end
            field_element = scaffold_value(record, f).to_s + hidden_field_tag(html_name(model, colname, name_prefix), val)
          else
            field_element = scaffold_field(record, f, name_prefix)
          end
          e = nil
          e = record.errors.on(model.column_name_by_attribute(f).to_sym) unless options[:hide_validation_errors]
          eclass = e.nil? ? nil : 'error'
          e = "'#{h(record.send(f))}' #{h(e)}" if e
          content_tag('tr',
            content_tag('th', scaffold_field_name(record, f) + ":") +
            content_tag('td', field_element)+
            content_tag('td', h(e), :class=>eclass)
          )
        }.join().html_safe,
        :class=>"record-form"
      ) + invisible_fields.map{|inv_f|
        colname = model.column_name_by_attribute(inv_f)
        val = record.send(colname)
        if val.class==TrueClass
          val = 't'
        elsif val.class == FalseClass
          val = 'f'
        end
        hidden_field_tag(html_name(model, colname, name_prefix), val)
      }.join().html_safe + invisible_fields.map{|inv_f| hidden_field_tag('invisible_fields[]', inv_f)}.join().html_safe + lock_field
    ) 
  end
  def record_form_quer_zeile(record, options={})
    model = record.class
    fields = record.class.scaffold_fields
    name_prefix = options[:name_prefix] # nil default
    fixed_fields = options[:fixed_fields] || []
    invisible_fields = options[:invisible_fields] || []
    fields -= invisible_fields
    count=0

    hidden = invisible_fields.map{|inv_f|
        hidden_field_tag(html_name(model, inv_f, name_prefix), record.send(inv_f))
    }.join()
    content_tag('tr',
      fields.map{|f|
        field_element = nil
        count += 1
        if fixed_fields.include?(f)
          field_element = scaffold_value(record, f)
        else
          field_element = scaffold_field(record, f, name_prefix)
        end
        if count==1
          content_tag('td', field_element.to_s+hidden)
        else
          content_tag('td', field_element)
        end
      }.join()
    ) 
  end
  # scaffolds an input field dependent on the column type
  def scaffold_field(record, field, name_prefix=nil, options={})
    if record.respond_to?("#{field}_immutable?") and record.send("#{field}_immutable?")
      model = record.class
      colname = model.column_name_by_attribute(field)
      val = record.send(colname)
      if val.class==TrueClass
        val = 't'
      elsif val.class == FalseClass
        val = 'f'
      end
      return (scaffold_value(record, field).to_s + hidden_field_tag(html_name(model, colname, name_prefix), val))
    end
    if field.to_s =~ /\./
      assoc, rest = field.to_s.split('.', 2)
      return record.send(assoc, rest, name_prefix)
    end
    if respond_to?("#{record.class.name.underscore}_#{field}_field")
      send("#{record.class.name.underscore}_#{field}_field", record, field, name_prefix)
    else
      begin
      model = record.class
      logger.debug("model: #{model}")
      assoc = model.reflect_on_association(field.to_sym)
      colname = model.column_name_by_attribute(field)
      column = model.columns_hash[colname.to_s]
      css_class = column.type.to_s
      if not column.null
        css_class << " notnull"
      end
      if assoc
        assoc_obj = record.send(field.to_sym)
        if assoc_obj && assoc_obj.new_record?
          return record_form(assoc_obj, {:name_prefix=>html_name(model, assoc.name, name_prefix)})
        end
        conditions, condition_params = build_conditions(assoc.klass, {})
        extra_params = nil # for inline browser
        if assoc.options.has_key?(:conditions)
          begin
            cond = record.instance_eval('"' + assoc.options[:conditions] + '"')
            conditions << cond
          rescue
          end
        end
        count = 0
        if assoc.options[:conditions]
          assoc.klass.send(:with_scope, :find=>{:conditions=>assoc.options[:conditions]}) do
            count = assoc.klass.count(:conditions=>[conditions.join(" AND "), *condition_params])
          end
        else
          count = assoc.klass.count(:conditions=>[conditions.join(" AND "), *condition_params])
        end
        if User.current_user and User.current_user.has_any_privilege?(["#{assoc.klass.name}::CREATE", "#{assoc.klass.name}::ALL", "Application::ALL"]) and options[:link_new] != false
          inlinenew = content_tag('span', '', 
                                         :class=>'inlinenew', 
                                         :url=>url_for( params.merge({
                                           :controller=>assoc.klass.name.underscore, 
                                           :action=>'new', 
                                           :clone_from=>nil,
                                           :inline=>1, 
                                           :name_prefix=>html_name(model, assoc.name, name_prefix)                                                                     })
                                         ),
                                         :title=>"#{assoc.klass.scaffold_model_name} neu anlegen"
                                        )
        else
          inlinenew = ""
        end
        if (model.scaffold_column_options(field.to_s)['edit_assoc'] == true rescue false) and not record.send(assoc.primary_key_name).nil?
          editlink = link_to(image_tag('edit.png'), 
                             {:action=>'edit', 
                              :controller=>assoc.klass.name.underscore, 
                              :id=>record.send(assoc.primary_key_name),
                              :redirect_to=>url_for()}, 
                             :title=>"Ausgewählte #{assoc.klass.scaffold_model_name} bearbeiten", 
                             :class=>'button')
        else
          editlink = ""
        end
        if count < 100 and (model.scaffold_column_options(field.to_s)['custom_renderer'] != :hidden_inline_browser rescue true)
          return content_tag('div', 
            association_select_tag(record, assoc, conditions, condition_params, name_prefix, css_class) + 
              content_tag('span', '', 
                :class=>'inlineshow', 
                :title=>"#{assoc.klass.scaffold_model_name} anzeigen",
                :url=>url_for(
                  :controller=>assoc.klass.name.underscore, 
                  :action=>'show' 
                )
              ) + inlinenew + editlink,
              :class=>'association'
            )
        end
        if assoc.options[:conditions].is_a?(Hash)
          extra_params = assoc.options[:conditions].map{|k,v| "search[#{assoc.klass.name.underscore}][#{k}]=#{URI.encode(v.to_s, /[^a-zA-Z0-9.,]/)}"}.join("&")
        else
          extra_params = nil
        end
        return content_tag('div',
            content_tag('span', 
              hidden_field_tag(
                html_name(model, assoc.primary_key_name, name_prefix), 
                record.send(assoc.primary_key_name),
                :id=>html_id(model, field, name_prefix)
              ), 
              :class=>"inlinebrowser #{css_class}",
              :title=>"#{assoc.klass.scaffold_model_name} auswählen",
              :url=>url_for(:controller=>assoc.klass.name.underscore, :action=>'browse_data'),
              :header_url=>url_for(:controller=>assoc.klass.name.underscore, :action=>'headerspec'),
              :extra_params=>extra_params,
              :selected_text=>(record.send(assoc.name).scaffold_name rescue '&nbsp;&nbsp;&nbsp;')
            ) + inlinenew + editlink,
            :class=>'association'
          )
      end
      return case column.type
      when :string, :date
        size = model.scaffold_column_options(field.to_s).try(:[], 'size')
        size = 30 if size.nil?
        text_field_tag(html_name(model, field, name_prefix), record.send(field), :class=>css_class,
                      :id=>html_id(model, field, name_prefix), :size=>size)
      when :integer, :decimal, :numeric, :float
        size = model.scaffold_column_options(field.to_s).try(:[], 'size')
        size = 30 if size.nil?
        text_field_tag(html_name(model, field, name_prefix), record.send(field).to_s.gsub(".", ","), :class=>css_class,
                      :id=>html_id(model, field, name_prefix), :size=>size)
      when :text
        opt = model.scaffold_column_options(field.to_s)
        html_options = {:class=>css_class, :rows=>5, :cols=>80, :wrap=>'off'}
        html_options[:rows] = opt['rows'] if opt.is_a?(Hash) && opt.has_key?('rows')
        html_options[:cols] = opt['cols'] if opt.is_a?(Hash) && opt.has_key?('cols')
        html_options[:id] = html_id(model, field, name_prefix)
        text_area_tag(html_name(model, field, name_prefix), record.send(field), html_options)
      when :boolean
        select_tag(html_name(model, field, name_prefix),
                   options_for_select([["", nil], ["Ja", "t"],["Nein", "f"]], record.send(field).to_s.slice(0...1)),
                   :class=>css_class,
                   :id=>html_id(model, field, name_prefix) 
                  )
        #check_box_tag(html_name(model, field, name_prefix), "t", record.send(field + "?"), :class=>css_class)
      when :binary
        file_field_tag(html_name(model, field, name_prefix))
      end
      rescue Exception=>e
        h(e.to_s) + " Feld " + field.to_s
      end
    end
  end
  # determines the query parameter name for a field of a ActiveRecord class
  # * <tt>name_prefix</tt> is an optional parameter 
  def html_name(model_class, field, name_prefix=nil)
    name_prefix.nil? ? "#{model_class.name.underscore}[#{field}]" : "#{name_prefix}[#{field}]"
  end
  def html_id(model_class, field, name_prefix=nil)
    name_prefix.nil? ? "#{model_class.name.underscore}_#{field}" : "#{name_prefix.gsub("[", "_").gsub("]", "")}_#{field}"
  end

  # creates a select box for the +has_many+ association assoc
  # displayed values are determined by calling the +scaffold_name+ method of each instance
  # entries are ordered by +scaffold_select_order+ of the associated model
  def association_select_tag(record, assoc, conditions, condition_params, name_prefix, css_class)
    model = record.class
    data = nil
    if assoc.options[:conditions]
      assoc.klass.send(:with_scope, :find=>{:conditions=>assoc.options[:conditions]}) do
        data = assoc.klass.find(:all, 
            :conditions=>[conditions.join(" AND "), *condition_params], 
            :order=>assoc.klass.scaffold_select_order
          ).map{|row| 
            [row.scaffold_name, row.id]
          } 
      end
    else
      data = assoc.klass.find(:all, 
          :conditions=>[conditions.join(" AND "), *condition_params], 
          :order=>assoc.klass.scaffold_select_order
        ).map{|row| 
          [row.scaffold_name, row.id]
        } 
    end
    select_tag(html_name(model, assoc.primary_key_name, name_prefix), 
      options_for_select([["", ""]] + data,
        record.send(assoc.primary_key_name)
      ),
      :class=>css_class,
      :id=>html_id(model, assoc.primary_key_name, name_prefix)
    )
  end
end
