require 'rubygems'
require 'rake'
require 'rake/testtask'
#require 'rake/rdoctask'
require 'rdoc/task'
require 'rake/packagetask'
#require 'rake/gempackagetask'
require "rubygems/packagetask"
require 'spec/rake/spectask'
PKG_NAME="scaffolding_esda"
PKG_VERSION="0.9"
dist_dirs = [ "tools", "lib", "rails", "scaffolds_tng", "test", "public" ]
spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = PKG_NAME
  s.version = PKG_VERSION
  s.summary = "A scaffolding extension for Ruby on Rails"
  s.description = %q{}

  s.files = [ "Rakefile", "README", "CHANGELOG", "TODO" ]
  dist_dirs.each do |dir|
    s.files = s.files + Dir.glob( "#{dir}/**/*" ).delete_if { |item| item.include?( "\.svn" ) }
  end

  s.add_dependency('rails', '= 2.3.4')

  s.require_path = 'lib'
  #s.autorequire = 'active_record'

  s.has_rdoc = true
  s.extra_rdoc_files = %w( README )
  s.rdoc_options.concat ['--main',  'README']

  s.author = "Daniel Schreiber"
  s.email = "schreiber@esda.com"
  s.homepage = "http://gitorious.org/scaffolding_esda"
  s.rubyforge_project = "scaffolding_esda"
end
Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end

namespace :scaffolding_esda do
  task :install_assets do
    puts RAILS_ROOT
  end
end

desc 'Run the specs'
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_opts = ['--colour --format progress --loadby mtime --reverse']
  t.spec_files = FileList['spec/**/*_spec.rb']
end
namespace :spec do
  desc "Run all specs in spec directory with RCov (excluding plugin specs)"
  Spec::Rake::SpecTask.new(:rcov) do |t|
    t.spec_opts = ['--options', "\"spec/spec.opts\""]
    t.spec_files = FileList['spec/**/*_spec.rb']
    t.rcov = true
    t.rcov_opts = lambda do
      IO.readlines("spec/rcov.opts").map {|l| l.chomp.split " "}.flatten
    end
  end
end
