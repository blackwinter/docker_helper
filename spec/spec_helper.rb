$:.unshift('lib') unless $:.first == 'lib'

require 'docker_helper'

RSpec.configure { |config|
  config.mock_with(:rspec) { |c| c.verify_partial_doubles = true }

  config.include(Module.new {
    def expect_pipe(result, *args)
      expect(subject).to receive(:docker_pipe).with('sudo', /\Adocker(?:\.io)?\z/, *args).and_return(result)
      expect(subject).not_to receive(:docker_system)
    end

    def expect_system(result, *args)
      expect(subject).to receive(:docker_system).with('sudo', /\Adocker(?:\.io)?\z/, *args).and_return(result)
      expect(subject).not_to receive(:docker_pipe)
    end
  })
}
