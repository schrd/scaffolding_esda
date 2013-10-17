module Esda::Scaffolding::Helper::LegacyHelper
  def scaffold_form(action)
    if @scaffold_singular_object
      inst = @scaffold_singular_object
    elsif @scaffold_singular_name
      inst = instance_variable_get("@#{@scaffold_singular_name}")
    else
      inst = @instance
    end
    if action == 'create'
      aktion = 'anlegen'
    else
      aktion = 'ändern'
    end
    out = form_tag(:action=>action, :id=>inst.id)
    out << record_form(inst)
    out << hidden_field_tag('redirect_to', params[:redirect_to]) if params[:redirect_to].to_s != ''
    out << submit_tag(aktion)
    out << "</form>".html_safe
    out
  end
  def manage_link
  end
end
class ActiveRecord::Base
    @@scaffold_table_classes = {:form=>'formtable', :list=>'sortable', :show=>'sortable'}
      def self.scaffold_table_class(type)
        @scaffold_table_classes ||= @@scaffold_table_classes
        @scaffold_table_classes[type]
      end
end
module ActionView
  module Helpers
    module ActiveRecordHelper
      def input(record_name, method, options = {})
        record = assigns[record_name.to_s]
        record = self.instance_variable_get("@#{record_name.to_s}") if record.nil?
        return scaffold_field(record, method)
      end

      # Uses a table to display the form widgets, so that everything lines up
      # nicely.  Handles associated records. Also allows for a different set
      # of fields to be specified instead of the default scaffold_fields.
      def all_input_tags(record, record_name, options)
        input_block = options[:input_block] || default_input_block
        rows = (options[:fields] || record.class.scaffold_fields).collect do |field|
          reflection = record.class.reflect_on_association(field.to_sym)
          if reflection
            input_block.call(record_name, reflection) 
          else
            input_block.call(record_name, record.column_for_attribute(field))
          end
        end
        "\n<table class='#{record.class.scaffold_table_class :form}'><tbody>\n#{rows.join}</tbody></table><br />".html_safe
      end

      # Wraps each widget and widget label in a table row
      def default_input_block
        Proc.new do |record, column| 
          begin
            if assigns.has_key?("@scaffold_class")
              record_class = assigns["@scaffold_class"]
            else
              record_class = record.classify.constantize
            end
            newrec = record_class.new
            if column.class.name =~ /Reflection/
              #logger.debug("default_input_block: " + record.camelize.constantize.scaffold_column_types.inspect)
              if column.macro == :belongs_to
                #"<tr><td>#{column.name.to_s.humanize}:</td><td>#{association_select_tag(record, column.name)}</td></tr>\n"
              "<tr><td>#{scaffold_field_name(newrec, column.name.to_s)}: #{feldhilfe(record, column.name)}</td><td>#{input(record, column.name)}</td></tr>\n"
              end
            else
            "<tr><td>#{scaffold_field_name(newrec, column.name)}: #{feldhilfe(record, column.name)}</td><td>#{input(record, column.name)}</td></tr>\n"
            end  
          rescue Exception=>e
            logger.debug("Exception in #{record}/#{column}")
            raise e.class, e.message, (["While executing block for #{record}/#{column.name}"] | e.backtrace)
          end
        end
      end

      # Returns a select box displaying the possible records that can be associated.
      # If scaffold autocompleting is turned on for the associated model, uses
      # an autocompleting text box.  Otherwise, creates a select box using
      # the associated model's scaffold_name and scaffold_select_order.
      def association_select_tag(record, association, notnull=false,htmloptions={})
        logger.debug("record: #{record.inspect}, association: #{association.inspect}")
        reflection = record.camelize.constantize.reflect_on_association(association)
        foreign_key = reflection.options[:foreign_key] || reflection.klass.table_name.classify.foreign_key
        null = (record.camelize.constantize.columns_hash[foreign_key].null rescue false)
        if null.nil?
          options = false
        else
          options = (null or notnull) ? {}.merge(htmloptions) : {:class=>'notnull'}.merge(htmloptions)
        end
        logger.debug "HTMLOPTIONS3: #{options.inspect}"
        if reflection.klass.scaffold_use_auto_complete
          scaffold_text_field_with_auto_complete(record, foreign_key, reflection.klass.name.underscore, options)
        else
          items = reflection.klass.find(:all, :order => reflection.klass.scaffold_select_order, :conditions=>reflection.options[:conditions], :include=>reflection.klass.scaffold_include, :limit=>100)
          items.sort! {|x,y| x.scaffold_name <=> y.scaffold_name} if reflection.klass.scaffold_include
          # include a blank entry only if the column is nullable
          select(record, foreign_key, items.collect{|i| [i.scaffold_name, i.id]}, {:include_blank=>null}, options) +
            javascript_tag("prepareselect('#{record}_#{foreign_key}')")

        end
      end
      class InstanceTag
        # Gets the default options for the attribute and merges them with the given options.
        # Chooses an appropriate widget based on attribute's column type.
        def to_tag(options = {})
          options = (object.class.scaffold_column_options(@method_name) || {}).merge(options)
          case column_type
          when :string, :integer, :float, :decimal
            to_input_field_tag("text", options)
          when :password
            to_input_field_tag("password", options)
          when :text
            to_text_area_tag(options)
          when :date
            to_date_select_tag(options)
          when :datetime
            to_datetime_select_tag(options)
          when :boolean
            to_boolean_select_tag(options)
          end
        end

        # Returns three valued select widget, for null, false, and true, with the appropriate
        # value selected
        def to_boolean_select_tag(options = {})
          options = options.stringify_keys
          add_default_name_and_id(options)
          value = value(object)
        "<select#{tag_options(options)}><option value=''#{selected(value.nil?)}>&nbsp;</option><option value='f'#{selected(value == false)}>Nein</option><option value='t'#{selected(value)}>Ja</option></select>"
        end

        # Returns XHTML compliant fragment for whether the value is selected or not
        def selected(value)
          value ? " selected='selected'" : '' 
        end

        # Changes the default date_select to input type text with size 10, suitable
        # for MM/DD/YYYY or YYYY-MM-DD date format, both of which apparently handled
        # fine by ActiveRecord.
        def to_date_select_tag(options = {})
          add_default_name_and_id(options)
          to_input_field_tag('text', {'size'=>'10'}.merge(options)) +
                "<button type='reset' id='" + options["id"] + "_button'>...</button>" +
                '<script type="text/javascript">
                 Calendar.setup({
                   inputField  : "' + options["id"] + '",
                   ifFormat    : "%d.%m.%Y",
                   button      : "'+ options["id"] +'_button",
                   firstDay    : 1
                 });
                 </script>'
        end


        # Allow overriding of the column type by asking the ActiveRecord for the appropriate column type.
        def column_type
          object.class.scaffold_column_type(@method_name)
        end
      end
    end
  end
end

