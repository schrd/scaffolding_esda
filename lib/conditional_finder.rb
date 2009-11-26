module ConditionalFinder
  # returns two arrays:
  # * <tt>conditions</tt> is a arry that has to be joined by " AND "
  # * <tt>condition_params</tt> is a list of values that have to be interpolated into the conditions.
  #
  # Use it like this:
  #
  #   conditions, condition_params = build_conditions(MyModel, params[MyModel.name.underscore])
  #   results = MyModel.find(:all, :conditions=>[conditions.join(" AND "), *condition_params])
  #
  # The method does know how to traverse +belongs_to+ hierarchies as defined in
  # +scaffold_browse_fields+, so parameters such as <tt>my_model[other_model.fieldA]</tt> are handled correctly
  #
  def build_conditions(model_class, params_part)
    conditions = ['1=1']
    condition_params = []
    includes, join_deps = model_class.browse_include_fields2
    table = model_class.table_name
    jd = ActiveRecord::Associations::ClassMethods::JoinDependency.new(model_class, includes, nil)
    (model_class.scaffold_browse_fields + model_class.scaffold_fields ).uniq.each{|sbf|
      if sbf =~ /\./
        dep = join_deps[ sbf.split('.')[0..-2].join('.') ]
        #puts "#{sbf}, #{sbf.split('.')[0..-2].join('.')}, #{dep}"
        table = jd.joins[dep].aliased_table_name
        model_class2 = jd.joins[join_deps[ sbf.split('.')[0..-2].join('.') ]].reflection.klass
        field = model_class2.column_name_by_attribute(sbf.split('.').last)
        param_name = sbf.to_sym
      else
        table = model_class.table_name
        model_class2 = model_class
        field = model_class.column_name_by_attribute(sbf)
        param_name = field.to_sym
      end
      next unless params_part.has_key?(param_name.to_sym)
      column = model_class2.columns_hash[field]
      case column.type
      when :string, :text
        if not params_part[param_name].blank?
          conditions << "UPPER(#{table}.#{field}) LIKE UPPER(?)"
          condition_params << params_part[param_name] + '%'
        end
      when :boolean
        if not params_part[param_name].blank?
          conditions << "#{table}.#{field} = ?"
          condition_params << params_part[param_name]
        end
      when :date
        if params_part[param_name][:from].to_s =~ /^\d{1,2}\.\d{1,2}\.\d{4}$/
          conditions << "#{table}.#{field} >= ?"
          condition_params << Date.strptime(params_part[param_name][:from], "%d.%m.%Y")
        end
        if params_part[param_name][:to].to_s =~ /^\d{1,2}\.\d{1,2}\.\d{4}$/
          conditions << "#{table}.#{field} <= ?"
          condition_params << Date.strptime(params_part[param_name][:to], "%d.%m.%Y")
        end
      when :integer, :float, :decimal
        regex = /^-?\d+$/
        if column.type == :float or column.type == :decimal
          regex = /^-?\d+([.,]\d+)?$/
        end
        cast_method = case column.type
                      when :integer
                        :to_i
                      when :float
                        :to_f
                      when :decimal
                        :to_d
                      end
        if (params_part[param_name][:from].to_s =~ regex rescue false)
          conditions << "#{table}.#{field} >= ?"
          condition_params << params_part[param_name][:from].to_s.gsub(/,/, ".").send(cast_method)
        end
        if (params_part[param_name][:to].to_s =~ regex rescue false)
          conditions << "#{table}.#{field} <= ?"
          condition_params << params_part[param_name][:to].to_s.gsub(/,/, ".").send(cast_method)
        end
        if (params_part[param_name].is_a?(Array) and params_part[param_name].size > 1)
          conditions << "#{table}.#{field} IN (?)"
          condition_params << params_part[param_name].map{|e| e.to_s.gsub(/,/, ".").send(cast_method)}
        elsif (params_part[param_name].to_s =~ regex rescue false)
          conditions << "#{table}.#{field} = ?"
          condition_params << params_part[param_name].to_s.gsub(/,/, ".").send(cast_method)
        end
      end # case
    }
    return conditions, condition_params
  end
end
