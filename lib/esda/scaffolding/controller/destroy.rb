module Esda::Scaffolding::Controller::Destroy
  def destroy
    begin
      @instance = model_class.find(params[:id])
      @instance.destroy
      if params.has_key?(:redirect_to)
        return(redirect_to(params[:redirect_to]))
      end
      render(:inline=>'Datensatz gelöscht', :layout=>(request.xhr? ? false : 'esda'))
    rescue ActiveRecord::InvalidForeignKey=>e
      render(:inline=>"Datensatz kann nicht gelöscht werden, weil er von anderen Datensätzen referenziert wird: #{e.message}", :layout=>(request.xhr? ? false : 'esda'))
    rescue ActiveRecord::RecordNotFound
      render :inline=>'Datensatz nicht gefunden', :status=>404
    end
  end
end
