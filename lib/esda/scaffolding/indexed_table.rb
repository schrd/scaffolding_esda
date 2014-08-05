module Esda::Scaffolding::IndexedTable
  def indexed_table
    @model_class = model_class
    @instance = model_class.find(params[:id])
    position_assoc = @model_class.reflect_on_association(@model_class.position_association)
    @position_model = position_assoc.klass
    position_reverse_assoc = @position_model.reflect_on_all_associations.find{|assoc| assoc.macro==:belongs_to and assoc.klass==@instance.class}
    index_model = model_class.index_association.to_s.classify.constantize
    possible_associations = position_assoc.klass.reflect_on_all_associations.find_all{|assoc|
      assoc.macro==:belongs_to and assoc.klass==index_model 
    }
    if possible_associations.size != 1
      raise "Can't find unique association of Class #{index_model.name} in association #{position_assoc.name}"
    else
      @posision_index_association = possible_associations.first
    end
    @index_instance = index_model.find(params[@position_model.name.underscore][@posision_index_association.foreign_key])


    render :inline=>"<%= indexed_table(@position_model, @instance, @instance.class.primary_key, @index_instance, @posision_index_association.foreign_key) %>"
  end
end
