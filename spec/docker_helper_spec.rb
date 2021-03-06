describe DockerHelper do

  subject { Object.new.extend(described_class) }

  describe '#version' do

    it 'should return the client version' do
      expect_pipe('Client version: 1.2.3', 'version', {})
      expect(subject.docker_version).to eq('1.2.3')
    end

  end

  describe '#tags' do

    it 'should return the image tags' do
      expect_pipe(<<-EOT, 'images', {})
REPOSITORY                       TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
foo/bar                          baz                 123                 now                 0.0
quix                             1.1                 456                 yesterday           0.0
quix                             1.0                 789                 a week ago          0.0
      EOT

      expect(subject.docker_tags('quix')).to eq(%w[1.0 1.1])
    end

  end

  describe '#build' do

    it 'should build the image' do
      expect_system(true, 'build', '-t', 'foo', 'bar', {})
      expect(subject.docker_build('bar', 'foo')).to eq(true)
    end

  end

  describe '#volume' do

    it 'should return the volume path' do
      expect_pipe('path', 'inspect', '-f', '{{index .Volumes "volume"}}', 'foo', {})
      expect(subject.docker_volume('volume', 'foo')).to eq('path')
    end

  end

  describe '#port' do

    it 'should return the port' do
      expect_pipe('0.0.0.0:42', 'port', 'foo', '23', {})
      expect(subject.docker_port(23, 'foo')).to eq('0.0.0.0:42')
    end

  end

  describe '#url' do

    it 'should return the URL' do
      expect_pipe('0.0.0.0:42', 'port', 'foo', '23', {})
      expect(subject.docker_url(23, 'foo')).to eq('http://0.0.0.0:42')
    end

  end

  describe '#ready' do

    def expect_socket(result)
      expect(subject).to receive(:docker_socket_ready).with(
        *@host_with_port_ary, a_kind_of(Integer), a_kind_of(Float)
      ).and_return(result)
    end

    def expect_http(result)
      expect(subject).to receive(:docker_http_ready).with(
        *@host_with_port_ary, @path, a_kind_of(Integer), a_kind_of(Float)
      ).and_return(result)
    end

    before do
      @host_with_port_str = '0.0.0.0:42'
      @host_with_port_ary = @host_with_port_str.split(':')
    end

    describe 'when socket ready' do

      before do
        expect_socket(true)
      end

      describe 'without path' do

        before do
          expect(subject).not_to receive(:docker_http_ready)
        end

        it 'should return true with string' do
          expect(subject.docker_ready(@host_with_port_str)).to eq(true)
        end

        it 'should return true with array' do
          expect(subject.docker_ready(@host_with_port_ary)).to eq(true)
        end

      end

      describe 'with path' do

        before do
          @path = '/path'
        end

        describe 'when HTTP ready' do

          before do
            expect_http(true)
          end

          it 'should return true with string' do
            expect(subject.docker_ready(@host_with_port_str, @path)).to eq(true)
          end

          it 'should return true with array' do
            expect(subject.docker_ready(@host_with_port_ary, @path)).to eq(true)
          end

        end

        describe 'when HTTP not ready' do

          before do
            expect_http(false)
          end

          it 'should return false with string' do
            expect(subject.docker_ready(@host_with_port_str, @path)).to eq(false)
          end

          it 'should return false with array' do
            expect(subject.docker_ready(@host_with_port_ary, @path)).to eq(false)
          end

        end

      end

    end

    describe 'when socket ready' do

      before do
        expect_socket(false)
        expect(subject).not_to receive(:docker_http_ready)
      end

      describe 'without path' do

        it 'should return false with string' do
          expect(subject.docker_ready(@host_with_port_str)).to eq(false)
        end

        it 'should return false with array' do
          expect(subject.docker_ready(@host_with_port_ary)).to eq(false)
        end

      end

      describe 'with path' do

        before do
          @path = '/path'
        end

        it 'should return false with string' do
          expect(subject.docker_ready(@host_with_port_str, @path)).to eq(false)
        end

        it 'should return false with array' do
          expect(subject.docker_ready(@host_with_port_ary, @path)).to eq(false)
        end

      end

    end

  end

  describe '#start' do

    it 'should start the container' do
      expect_system(true, 'run', '-d', '-P', '--name', 'foo', 'bar', {})
      expect(subject.docker_start('foo', 'bar')).to eq(true)
    end

  end

  describe '#start!' do

    describe 'when already running' do

      before do
        expect_system(true, 'stop', 'foo', err: :close)
        expect_system(true, 'start', 'foo', {})
      end

      describe 'without a block' do

        it 'should restart the container' do
          expect(subject.docker_start!('foo', 'bar')).to eq(true)
        end

      end

      describe 'with a block' do

        it 'should ignore the block' do
          expect { |b| subject.docker_start!('foo', 'bar', &b) }.not_to yield_control
        end

      end

    end

    describe 'when not running' do

      before do
        expect_system(false, 'stop', 'foo', err: :close)
        expect_system(false, 'start', 'foo', {})
        expect_system(true, 'run', '-d', '-P', '--name', 'foo', 'bar', {})
      end

      describe 'without a block' do

        it 'should start the container' do
          expect(subject.docker_start!('foo', 'bar')).to eq(true)
        end

      end

      describe 'with a block' do

        it 'should start the container and yield control' do
          expect { |b| subject.docker_start!('foo', 'bar', &b) }.to yield_with_args('foo', 'bar')
        end

      end

    end

  end

  describe '#stop' do

    it 'should stop the container' do
      expect_system(true, 'stop', 'foo', err: :close)
      expect(subject.docker_stop('foo')).to eq(true)
    end

  end

  describe '#restart' do

    describe 'when already running' do

      it 'should restart the container' do
        expect_system(true, 'stop', 'foo', err: :close)
        expect_system(true, 'start', 'foo', {})
        expect(subject.docker_restart('foo')).to eq(true)
      end

    end

    describe 'when not running' do

      it 'should restart the container' do
        expect_system(false, 'stop', 'foo', err: :close)
        expect_system(true, 'start', 'foo', {})
        expect(subject.docker_restart('foo')).to eq(true)
      end

    end

  end

  describe '#clean' do

    it 'should remove the container' do
      expect_system(true, 'stop', 'foo', err: :close)
      expect_system(true, 'rm', '-v', '-f', 'foo', err: :close)
      expect(subject.docker_clean('foo')).to eq(true)
    end

  end

  describe '#clobber' do

    it 'should remove the container and the image' do
      expect_system(true, 'stop', 'foo', err: :close)
      expect_system(true, 'rm', '-v', '-f', 'foo', err: :close)
      expect_system(true, 'rmi', 'bar', err: :close)
      expect(subject.docker_clobber('foo', 'bar')).to eq(true)
    end

  end

  describe '#reset' do

    it 'should reset the container' do
      expect_system(true, 'stop', 'foo', err: :close)
      expect_system(true, 'rm', '-v', '-f', 'foo', err: :close)
      expect_system(true, 'run', '-d', '-P', '--name', 'foo', 'bar', {})
      expect(subject.docker_reset('foo', 'bar')).to eq(true)
    end

  end

end

describe DockerHelper, '::proxy' do

  subject { described_class.proxy }

  before do
    expect(subject).to receive(:docker_version).with(no_args).and_return('1.2.3')
  end

  it 'should respond to unabbreviated method' do
    expect(subject.docker_version).to eq('1.2.3')
  end

  it 'should respond to abbreviated method' do
    expect(subject.version).to eq('1.2.3')
  end

end
