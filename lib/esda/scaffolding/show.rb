module Esda::Scaffolding::Show
  def show
    begin
      @instance = model_class.find(params[:id])
      render_scaffold_tng "show"
    rescue ActiveRecord::RecordNotFound
      render :inline=>"Datensatz mit ID <%= params[:id].to_i %> nicht gefunden", :status=>404
    end
  end
end
