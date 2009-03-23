module Esda::Scaffolding::Model::AssociationHelper
  def include_to_table_names(model, inc)
    case inc
    when Array
      inc.map{|i|
        include_to_table_names(model, i)
      }
    when Hash
      inc.map{|new_model, new_inc|
        k = model.reflect_on_association(new_model).klass
        [ include_to_table_names(model, new_model),
        include_to_table_names(k, new_inc)]
      }
    when Symbol, String
      model.reflect_on_association(inc.to_sym).klass.table_name
    end
  end
end
