module Esda::Scaffolding::Helper::TableIndexedPositionHelper
  # generates a form for a position list
  # * instance is the head instance for positions
  # * position_assoc is the symbol of the association whis holds the positions
  # * index_model is the model that generates a position for each of its instances
  # * multiple can be either true, false or a symbol. If its a symbol the method with 
  #   that name of the index_model class ist evaluated to true/false. If multiple is 
  #   true, many positions with that index instance can be generated
  def table_indexed_position_form(instance, position_assoc, index_model, multiple, options={})
    if index_model.is_a?(Symbol)
      index_model = index_model.to_s.classify.constantize
    end
    position_assoc = instance.class.reflect_on_association(position_assoc)
    position_model = position_assoc.klass
    position_reverse_assoc = position_model.reflect_on_all_associations.find{|assoc| assoc.macro==:belongs_to and assoc.klass==instance.class}
    if options.has_key?(:position_index_association)
      posision_index_association = position_assoc.reflect_on_association(options[:position_index_association])
    else
      possible_associations = position_assoc.klass.reflect_on_all_associations.find_all{|assoc|
        assoc.macro==:belongs_to and assoc.klass==index_model 
      }
      if possible_associations.size != 1
        raise "Can't find unique association of Class #{index_model.name} in association #{position_assoc.name}"
      else
        posision_index_association = possible_associations.first
      end
    end
    index_model.find(:all, :order=>options[:index_order], :conditions=>options[:index_conditions]).map{|index_instance|
      tbl, empty = indexed_table(position_model, instance, instance.class.primary_key , index_instance, posision_index_association, position_reverse_assoc) 
      new_pos = ""
      multi = if multiple.is_a?(Symbol)
                index_instance.send(multiple)
              else
                multiple
              end
      new_pos = indexed_new(instance, index_instance, position_model, posision_index_association, position_reverse_assoc) if empty or multi
      content_tag("h2", h(index_instance.scaffold_name)) +
      content_tag('div',
        tbl + new_pos,
        :reload_url=>url_for(:controller=>instance.class.name.underscore, 
                             :action=>'indexed_table',
                             :id=>instance.id,
                             "#{position_model.name.underscore}[#{posision_index_association.foreign_key}]"=>index_instance.id
                            ),
        :class=>'indexedtable'
      )
    }.join("\n")
  end

  def indexed_table(model, head_instance, head_field, index_instance, index_assoc, position_reverse_assoc)
    instances = model.find(:all, 
                           :conditions=>["#{head_field}=? and #{index_assoc.foreign_key}=?", head_instance.id, index_instance.id], 
                           :order=>model.scaffold_select_order)
    if instances.size == 0
      return content_tag('div', "Keine Positionen"), true
    end
    if model.respond_to?(:scaffold_indexed_table_fields)
      fields = model.scaffold_indexed_table_fields
    else
      fields = model.scaffold_browse_fields
      fields -= [index_assoc.name.to_s, position_reverse_assoc.name.to_s]
    end
    headinst = model.new

    content = content_tag("table",
      content_tag("tr",
        content_tag("th", "") +
        fields.map{|f| content_tag("th",h(scaffold_field_name(headinst, f)))}.join("")
      ) +
      instances.map{|inst|
        content_tag("tr",
          content_tag("td", 
                      link_to(image_tag("edit.png"), 
                              :action=>'edit', 
                              :controller=>model.name.underscore, 
                              :id=>inst.id, 
                              :redirect_to=>url_for(),
                  "invisible_fields"=>[index_assoc.name, position_reverse_assoc.name]
                             ) +
                      link_to(image_tag("editdelete.png"),
                              :action=>'destroy', 
                              :controller=>model.name.underscore, 
                              :id=>inst.id, 
                              :redirect_to=>url_for()
                             )
                     ) +
          fields.map{|f|
            content_tag('td', scaffold_value(inst, f))
          }.join("")          
        )
      }.join("\n"),
      :class=>'indexed_table'
    )
    return content, false
  end

  def indexed_new(instance, index_instance, position_model, posision_index_association, position_reverse_assoc)
    content_tag('div', '', :class=>"newdialog") + 
    link_to(image_tag("filenew.png"), 
            {
                  :action=>'new', :controller=>position_model.name.underscore,
                  "fixed_fields"=>[posision_index_association.name, position_reverse_assoc.name],
                  "#{position_model.name.underscore}[#{posision_index_association.foreign_key}]"=>index_instance.id,
                  "#{position_model.name.underscore}[#{position_reverse_assoc.foreign_key}]"=>instance.id,
                    :redirect_to=>url_for()
            },
            :class=>"newdialog")
  end
end
