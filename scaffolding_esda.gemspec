Gem::Specification.new do |s|
  s.name = "scaffolding_esda"
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Daniel Schreiber"]
  s.date = "2014-03-17"
  s.description = "scaffolding extension from esda"
  s.email = "schreiber@esda.com"
  #s.extra_rdoc_files = [
  #  "LICENSE.txt",
  #  "README.rdoc"
  #]
  s.files = Dir[
    "lib/**/*.rb",
    "lib/assets/**/*",
    "scaffolds_tng/**",
    "COPYING",
    "README"
  ]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.25"
  s.summary = "An extended scaffolding extension extracted from Esda ERP system"
  s.add_dependency "rails", ">= 4.1.0", "< 5.0"
  s.add_dependency "handlebars_assets"
  s.add_dependency "jquery-ui-rails"
  s.add_dependency "jquery-turbolinks"

  s.add_dependency "gettext", '>= 3.0.2'
  s.add_runtime_dependency "gettext_i18n_rails"
  s.add_runtime_dependency "fast_gettext", '>= 0.5'

end


