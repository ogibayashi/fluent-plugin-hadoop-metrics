# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "fluent-plugin-hadoop-metrics"
  s.version     = "0.0.1"
  s.authors     = ["Hironori Ogibayashi"]
  s.email       = ["ogibayashi@mayoya.com"]
  s.homepage    = ""
  s.summary     = %q{Fluentd input plugin to collect hadoop metrics}
  s.description = %q{Fluentd input plugin to collect hadoop metrics}

  s.rubyforge_project = "fluent-plugin-hadoop-metrics"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "fluentd"
  s.add_development_dependency "hadoop-metrics"
  s.add_runtime_dependency "fluentd"
  s.add_runtime_dependency "hadoop-metrics"
end
