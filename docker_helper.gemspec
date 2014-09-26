# -*- encoding: utf-8 -*-
# stub: docker_helper 0.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "docker_helper"
  s.version = "0.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Jens Wille"]
  s.date = "2014-09-26"
  s.description = "Control the Docker command-line client from Ruby."
  s.email = "jens.wille@gmail.com"
  s.extra_rdoc_files = ["README", "COPYING", "ChangeLog"]
  s.files = ["COPYING", "ChangeLog", "README", "Rakefile", "lib/docker_helper.rb", "lib/docker_helper/pool.rb", "lib/docker_helper/proxy.rb", "lib/docker_helper/version.rb", "spec/docker_helper_spec.rb", "spec/spec_helper.rb"]
  s.homepage = "http://github.com/blackwinter/docker_helper"
  s.licenses = ["AGPL-3.0"]
  s.post_install_message = "\ndocker_helper-0.0.2 [2014-09-26]:\n\n* Added DockerHelper#docker_ready.\n* Added DockerHelper#docker_port.\n* Added DockerHelper::Pool.\n\n"
  s.rdoc_options = ["--title", "docker_helper Application documentation (v0.0.2)", "--charset", "UTF-8", "--line-numbers", "--all", "--main", "README"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3")
  s.rubygems_version = "2.4.1"
  s.summary = "Helper methods to interact with Docker."

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<hen>, [">= 0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<hen>, [">= 0"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<hen>, [">= 0"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end
