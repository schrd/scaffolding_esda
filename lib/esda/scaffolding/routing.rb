module Esda::Scaffolding::Routing
  # use in config routes as replacement for resources. It will automatically
  # include collection and member actions required by scaffolding
  def scaffold_resource(res, &block)
    resources res do
      if block_given?
        block.call
      end
      collection do
        get 'browse_data'
        get 'browse'
        get 'headerspec'
      end
      member do
        get 'download'
        get 'history'
      end
    end
  end
end
