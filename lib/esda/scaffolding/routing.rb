module Esda::Scaffolding::Routing
  # use in config routes as replacement for resources. It will automatically
  # include collection and member actions required by scaffolding
  def scaffold_resource(res, &block)
    ResourceRegistry.instance.add_resource(res)
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
  class ResourceRegistry
    include Singleton
    def initialize
      @resources = Set.new
    end
    attr_reader :resources

    def add_resource(r)
      @resources.merge([r])
    end
  end
end
