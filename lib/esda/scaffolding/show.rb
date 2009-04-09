module Esda::Scaffolding::Show
  def show
    begin
      @instance = model_class.find(params[:id])
      @tab_associations = model_class.reflect_on_all_associations.find_all{|a| 
        a.macro==:has_many and not a.options.has_key?(:through)
      }.sort_by{|a| 
        a.name.to_s.humanize
      }
      if request.xhr?
        render_scaffold_tng "show_inline"
      else
        render_scaffold_tng "show"
      end
    rescue ActiveRecord::RecordNotFound
      render :inline=>"Datensatz mit ID <%= params[:id].to_i %> nicht gefunden", :status=>404
    end
  end
end
