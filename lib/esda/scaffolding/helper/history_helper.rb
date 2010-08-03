module Esda::Scaffolding::Helper::HistoryHelper
  def records_show_history(records, options={})
    return "" if records.size == 0
    record = records.first
    if respond_to?("#{record.class.name.underscore}_records_show_history")
      return send("#{record.class.name.underscore}_records_show_history", records, options)
    else
      model = record.class
      fields = record.class.scaffold_fields
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
            content_tag('th', '') +
            records.map{|rec|
              nav_after = ((rec.object_id == records.first.object_id and rec.attributes.has_key?(log_id_field)) ? 
                           link_to("&larr;", :action=>'history', :id=>rec.id, :after=>middle_id) + "&nbsp;" : "")
              nav_before = (rec.object_id == records.last.object_id ? 
                           "&nbsp;" + link_to("&rarr;", :action=>'history', :id=>rec.id, :before=>middle_id) : "")
              ts_text = rec.respond_to?(:date_on) ?
                  h("#{scaffold_value(rec, :date_on)} - #{scaffold_value(rec, :date_off)}") :
                  scaffold_value(rec, :updated_at)

              content_tag('th', nav_after + ts_text + nav_before)
            }.join
          ) + 
          fields.map{|f|
            content_tag('tr',
              content_tag('th', scaffold_field_name(record, f)) +
              records.zip((0...records.size).to_a).map{|rec, idx|
                begin
                  if diff_fields[idx] and diff_fields[idx].include?(f)
                    content_tag('td', scaffold_value(rec, f, false), :class=>'changed')
                  else
                    content_tag('td', scaffold_value(rec, f, false)) 
                  end
                rescue ActiveRecord::MissingAttributeError
                  ""
                end
              }.join
            )
          }.join,
          :class=>"record-show"
        )
      )

    end
  end
end