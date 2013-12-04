# coding: UTF-8

module Esda::Scaffolding::Helper::HistoryHelper
  def records_show_history(records, options={})
    return "" if records.size == 0
    record = records.first
    if respond_to?("#{record.class.name.underscore}_records_show_history")
      return send("#{record.class.name.underscore}_records_show_history", records, options)
    else
      model = record.class
      fields = record.class.scaffold_fields
      if model.column_names.include?("updated_by")
        fields << "updated_by"
      end
      name_prefix = options[:name_prefix] # nil default
      fixed_fields = options[:fixed_fields] || []
      invisible_fields = options[:invisible_fields] || []
      fields -= invisible_fields

      diff_fields = []
      records.each_with_index{|rec, idx|
        nxt = records[idx+1]
        next if nxt.nil?
        diff_fields[idx] = rec.differing_fields(nxt)
      }

      log_id_field = model.table_name + '_log_id'
      middle_id = (records[records.size/2].send(log_id_field) rescue nil)
      

      content_tag('div',
        content_tag('table',
          content_tag('tr',
            content_tag('th', h('')) +
            records.map{|rec|
              nav_after = ((rec.object_id == records.first.object_id and rec.attributes.has_key?(log_id_field)) ? 
                           link_to("&larr;".html_safe, :action=>'history', :id=>rec.id, :after=>middle_id) + "&nbsp;".html_safe : "".html_safe)
              nav_before = (rec.object_id == records.last.object_id ? 
                           "&nbsp;".html_safe + link_to("&rarr;".html_safe, :action=>'history', :id=>rec.id, :before=>middle_id) : "".html_safe)
              ts_text = rec.respond_to?(:date_on) ?
                  h("#{scaffold_value(rec, :date_on)} - #{scaffold_value(rec, :date_off)}") :
                  scaffold_value(rec, :updated_at)

              content_tag('th', nav_after + ts_text + nav_before)
            }.join.html_safe
          ) + 
          fields.map{|f|
            content_tag('tr',
              content_tag('th', scaffold_field_name(record, f)) +
              records.zip((0...records.size).to_a).map{|rec, idx|
                begin
                  if f == "updated_by"
                    content_tag('td', h(User.find_by_id(record.updated_by).try(:login)))
                  else
                    if diff_fields[idx] and diff_fields[idx].include?(f)
                      content_tag('td', scaffold_value(rec, f, false), :class=>'changed')
                    else
                      content_tag('td', scaffold_value(rec, f, false)) 
                    end
                  end
                rescue ActiveRecord::MissingAttributeError
                  h("")
                end
              }.join.html_safe
            )
          }.join.html_safe,
          :class=>"record-show"
        )
      )

    end
  end
end
