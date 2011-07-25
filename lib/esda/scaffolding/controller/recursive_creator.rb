module Esda::Scaffolding::Controller::RecursiveCreator
  protected
  # creates instance and creates new belongs_to associated objects if necessary
  def recursively_create(model_class, params_part, clone_from=nil)
    # create associations first
    associations = model_class.reflect_on_all_associations.find_all{|a| a.macro==:belongs_to}
    created_objects = {}
    associations.each {|assoc|
      # only create new association instance if there is no id assigned and parameters exist
      if params_part and params_part.has_key?(assoc.name) and params_part[assoc.name].is_a?(Hash) and params_part[assoc.primary_key_name].blank?
        created_objects[assoc.name] = recursively_create(assoc.klass, params_part[assoc.name])
      end
    }
    # now create the instance, initialize with all parameters that are either string or numeric type
    if params_part
      found = params_part.find_all{|k,v| v.is_a?(String) || v.is_a?(Numeric)}
      found = Hash[*found.flatten]
      params_part.find_all{|k,v| v.is_a?(File)||v.is_a?(Tempfile)}.each do |k,v|
        found[k] = v.read
      end
    else 
      found = nil
    end
    if clone_from
      if found
        found = clone_from.attributes.merge(found)
      else
        found = clone_from.attributes
      end
    end
    instance = model_class.new(found)
    instance.valid?
    created_objects.each{|method, obj|
      #if not obj.valid?
      #  instance.errors.add(method, "has errors")
      #end
      instance.send("#{method}=", obj[0])
    }
    #instance.save!
    return instance, created_objects
  end

  def recursively_save_created_objects(instance, created_objects)
    if created_objects.is_a?(Hash)
    created_objects.each{|method, obj|
      rec_instance = obj[0]
      rec_created = obj[1]
      recursively_save_created_objects(rec_instance, rec_created)
      instance.send("#{method}=", rec_instance)
    }
    end
    instance.save!
  end

  # updates attributes in the instance and creates new belongs_to associated objects if necessary
  def recursively_update(instance, params_part)
    model_class = instance.class
    associations = model_class.reflect_on_all_associations.find_all{|a| a.macro==:belongs_to}
    created_objects = {}
    associations.each {|assoc|
      # only create new association instance if there is no id assigned and parameters exist
      if params_part.has_key?(assoc.name) and params_part[assoc.name].is_a?(Hash) and params_part[assoc.primary_key_name].blank?
        created_objects[assoc.name] = recursively_create(assoc.klass, params_part[assoc.name])
      end
    }
    if params_part
      found = params_part.find_all{|k,v| v.is_a?(String) || v.is_a?(Numeric)}.to_a
    else
      found = []
    end
    instance.attributes = Hash[*found.flatten]
    instance.valid?
    created_objects.each{|method, obj|
      #if not obj.valid?
      #  instance.errors.add(method, "has errors")
      #end
      instance.send("#{method}=", obj[0])
    }
    #instance.save!
    return instance, created_objects
  end
end
