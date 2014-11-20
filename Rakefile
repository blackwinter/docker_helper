require_relative 'lib/docker_helper/version'

begin
  require 'hen'

  Hen.lay! {{
    gem: {
      name:         %q{docker_helper},
      version:      DockerHelper::VERSION,
      summary:      %q{Helper methods to interact with Docker.},
      description:  %q{Control the Docker command-line client from Ruby.},
      author:       %q{Jens Wille},
      email:        %q{jens.wille@gmail.com},
      license:      %q{AGPL-3.0},
      homepage:     :blackwinter,
      dependencies: %w[],

      required_ruby_version: '>= 1.9.3'
    }
  }}
rescue LoadError => err
  warn "Please install the `hen' gem. (#{err})"
end
