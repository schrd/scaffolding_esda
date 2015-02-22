module ScaffoldMenuHelper
  def scaffold_models_list
    resource_models = ResourceRegistry.instance.resources.map{|r|
      begin
        r.to_s.classify.constantize
      rescue Exception=>ignored
        nil
      end
    }.compact.sort_by{|m| m.name}
    
    resource_models.map{|m|
      content_tag('li', 
        link_to(h(m.scaffold_model_plural_name), {:controller=>m.name.underscore, :action=>'index'})
      )
    }.join(" ").html_safe
  end
end
