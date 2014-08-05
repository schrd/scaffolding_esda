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

end


