require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'rake/clean'

$: << 'lib'
$: << '../../osmlib-base/trunk/lib'

require 'OSM/Export'

task :default => :test

desc "Run the tests"
Rake::TestTask::new do |t|
    t.test_files = FileList['test/test*.rb']
    t.verbose = true
end

desc "Generate the documentation"
Rake::RDocTask::new do |rdoc|
    rdoc.rdoc_dir = 'rdoc/'
    rdoc.title    = "OSM Library Documentation - Export"
    rdoc.options << '--line-numbers' << '--inline-source'
    rdoc.rdoc_files = FileList['README', 'lib/**/*.rb', 'doc/*']
end

spec = Gem::Specification::new do |s|
    s.platform = Gem::Platform::RUBY

    s.name = 'osmlib-export'
    s.version = OSM::Export::VERSION
    s.summary = 'Library for exporting OpenStreetMap data'
    s.description = <<EOF
Flexible library for exporting OpenStreetMap data into other formats. Currently
KML, Shapefiles, and CSV are supported.
EOF
    s.author = 'Jochen Topf'
    s.email = 'jochen@topf.org'
    s.homepage = 'osmlib.rubyforge.org'
    s.rubyforge_project = 'osmlib'
    
    s.require_path = 'lib'
    s.test_files = FileList['test/test*.rb']

    s.has_rdoc = true
    s.extra_rdoc_files = ["README"]

    s.executables = ['osmexport']

    s.files = FileList["lib/**/*.rb", "LICENSE", "rakefile.rb", 'examples/*'] + s.test_files + s.extra_rdoc_files
    s.rdoc_options.concat ['--main',  'README']

    s.add_dependency('osmlib-base')
end

desc "Package the library as a gem"
Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_zip = true
    pkg.need_tar = true
end

