module Esda::Scaffolding::Destroy
  def destroy
    begin
      @instance = model_class.find(params[:id])
      @instance.destroy
      if params.has_key?(:redirect_to)
        return(redirect_to(params[:redirect_to]))
      end
      render(:inline=>'Datensatz gelöscht', :layout=>(request.xhr? ? false : 'esda_tng'))
    rescue ActiveRecord::RecordNotFound
      render :inline=>'Datensatz nicht gefunden', :status=>404
    end
  end
end
