class ScaffoldIndexController < ApplicationController
  def index
    @resource_models = ResourceRegistry.instance.resources.map{|r|
      begin
        r.to_s.classify.constantize
      rescue Exception=>ignored
        nil
      end
    }.compact.sort_by{|m| m.name}
  end
end
