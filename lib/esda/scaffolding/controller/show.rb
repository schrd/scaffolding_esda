module Esda::Scaffolding::Controller::Show
  def show
    begin
      @instance = model_class.find(params[:id])
      @tab_associations = model_class.reflect_on_all_associations.find_all{|a| 
        a.macro==:has_many and not a.options.has_key?(:through)
      }.sort_by{|a| 
        a.name.to_s.humanize
      }
      if model_class.respond_to?(:inline_association)
        @inline_association = model_class.inline_association
        @tab_associations -= [@inline_association]
      else
        @inline_association = nil
      end
      if request.xhr?
        render_scaffold_tng "show_inline"
      else
        render_scaffold_tng "show"
      end
    rescue ActiveRecord::RecordNotFound
      render :inline=>"Datensatz mit ID <%= params[:id].to_i %> nicht gefunden", :status=>404
    end
  end

  # This action is called for downloading binary data that is stored in a
  # :binary column in the database If the scaffold_value method is called for a
  # binary column (it is called by default in scaffolding), it generated a link
  # to this action. 
  # This action expects an :id and a :column parameter
  #
  # You can override the transmitted mime_type in the model:
  # Given a column pdf_document you have to implement the following method:
  # 
  # class MyModel
  #   def mime_type_for_pdf_document
  #     "application/pdf"
  #   end
  # end
  #
  # It will send application/pdf instead of application/octet-stream
  # 
  def download_column
    begin
      column = params[:column]
      if not model_class.columns_hash.has_key?(column)
        render :inline=>"Spalte nicht gefunden", :status=>404
        return
      end
      if model_class.columns_hash[column].type != :binary
        render :inline=>"Spalte nicht gefunden", :status=>404
        return
      end
      @instance = model_class.find(params[:id])
      mime_type = "application/octet-stream"
      if @instance.respond_to?("mime_type_for_#{column}")
        mime_type = @instance.send("mime_type_for_#{column}")
      end
      send_data(@instance.send(column), :type=>mime_type)

    rescue ActiveRecord::RecordNotFound
      render :inline=>"Datensatz mit ID <%= params[:id].to_i %> nicht gefunden", :status=>404
    end

  end
end
