#--
###############################################################################
#                                                                             #
# docker_helper -- Helper methods to interact with Docker                     #
#                                                                             #
# Copyright (C) 2014 Jens Wille                                               #
#                                                                             #
# Authors:                                                                    #
#     Jens Wille <jens.wille@gmail.com>                                       #
#                                                                             #
# docker_helper is free software; you can redistribute it and/or modify it    #
# under the terms of the GNU Affero General Public License as published by    #
# the Free Software Foundation; either version 3 of the License, or (at your  #
# option) any later version.                                                  #
#                                                                             #
# docker_helper is distributed in the hope that it will be useful, but        #
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY  #
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public      #
# License for more details.                                                   #
#                                                                             #
# You should have received a copy of the GNU Affero General Public License    #
# along with docker_helper. If not, see <http://www.gnu.org/licenses/>.       #
#                                                                             #
###############################################################################
#++

require 'net/http'

# Various helper methods to control the Docker command-line client. Main
# entrance point is the #docker helper. Use ::proxy for a self-contained
# controller object to call these methods on.
#
# See ::docker_command

module DockerHelper

  class << self

    # Setter for the Docker command (see ::docker_command).
    attr_writer :docker_command

    # call-seq:
    #   proxy -> aProxy
    #
    # Returns a new instance of Proxy with helper methods available both in
    # abbreviated and unabbreviated form.
    def proxy
      Proxy.new.extend(self)
    end

    # call-seq:
    #   docker_command -> aString
    #
    # Returns the Docker command or aborts if none could be found.
    #
    # Override by setting the +DOCKER_COMMAND+ environment variable
    # or by setting the +docker_command+ attribute on this module.
    def docker_command
      @docker_command ||= ENV.fetch('DOCKER_COMMAND') {
        find_docker_command || abort('Docker command not found.') }
    end

    # :category: Internal
    #
    # Tries to find the Docker command for the host system. Usually,
    # it's just +docker+, but on Debian-based systems it's +docker.io+.
    def find_docker_command
      commands = %w[docker docker.io]

      require 'nuggets/file/which'
      File.which_command(commands)
    rescue LoadError
      commands.first
    end

    # :category: Internal
    #
    # Extracts options hash from +args+ and applies default options.
    #
    # Returns the options hash as well as the values for +keys+, which
    # will be removed from the options.
    def extract_options(args, *keys)
      options = args.last.is_a?(Hash) ? args.pop : {}

      unless options.key?(:pipe)
        options[:pipe] = args.first.is_a?(Symbol)
      end

      unless options.key?(:fail_if_empty)
        options[:fail_if_empty] = options[:pipe]
      end

      [options, *keys.map(&options.method(:delete))]
    end

    # :category: Internal
    #
    # Builds arguments array suitable for #docker_system and #docker_pipe.
    #
    # Prefixes the command with +sudo+ unless the +NOSUDO+ environment
    # variable is set.
    #
    # Flattens all arguments, converts them to strings and appends the
    # options hash.
    def build_args(args, options)
      args.unshift(docker_command)
      args.unshift(:sudo) unless ENV['NOSUDO']

      args.flatten!
      args.map!(&:to_s) << options
    end

  end

  # call-seq:
  #   docker(cmd, args...)
  #   docker(cmd, args...) { ... }
  #
  # Central helper method to execute Docker commands.
  #
  # If the command (first argument) is a symbol or if the +pipe+ option
  # is set, runs the command through #docker_pipe and returns the result
  # as a string. Otherwise, runs the command through #docker_system and
  # returns +true+ or +false+, indicating whether the command exited
  # successfully or not.
  #
  # In the pipe case, calls #docker_fail when the +fail_if_empty+ option
  # is set and the command returned no result.
  #
  # In the system case, ignores errors when the +ignore_errors+ option
  # is set. The block is passed on to #docker_system if given.
  def docker(*args, &block)
    options, pipe, fail_if_empty, ignore_errors = DockerHelper.
      extract_options(args, :pipe, :fail_if_empty, :ignore_errors)

    DockerHelper.build_args(args, options)

    if pipe
      docker_pipe(*args).tap { |res|
        if fail_if_empty && !res
          docker_fail(*args)
        end
      }
    else
      if ignore_errors
        options[:err] = :close
        block ||= lambda { |*| }
      end

      docker_system(*args, &block)
    end
  end

  # call-seq:
  #   docker_version -> aString
  #
  # Returns the version number of the Docker client.
  #
  # Command reference: {docker version
  # }[https://docs.docker.com/reference/commandline/cli/#version]
  def docker_version
    docker(:version).lines.first.split.last
  end

  # call-seq:
  #   docker_tags(image) -> anArray
  #
  # Returns the tags associated with image +image+.
  #
  # Command reference: {docker images
  # }[https://docs.docker.com/reference/commandline/cli/#images]
  def docker_tags(image = nil)
    image ||= docker_image_name

    needle = image[/[^:]+/]

    docker(:images).lines.map { |line|
      repo, tag, = line.split
      tag if repo == needle
    }.compact.sort.sort_by { |tag|
      tag.split('.').map(&:to_i)
    }
  end

  # call-seq:
  #   docker_build(build_path, image)
  #
  # Builds the image +image+ from the Dockerfile and context at
  # +build_path+.
  #
  # Command reference: {docker build
  # }[https://docs.docker.com/reference/commandline/cli/#build]
  def docker_build(build_path, image = nil)
    image ||= docker_image_name

    docker %W[build -t #{image} #{build_path}]  # --force-rm
  end

  # call-seq:
  #   docker_volume(volume, name) -> aString
  #
  # Returns the path to volume +volume+ shared by container +name+.
  #
  # Command reference: {docker inspect
  # }[https://docs.docker.com/reference/commandline/cli/#inspect]
  def docker_volume(volume, name = nil)
    name ||= docker_container_name

    docker :inspect, %W[-f {{index\ .Volumes\ "#{volume}"}} #{name}]
  end

  # call-seq:
  #   docker_port(port, name) -> aString
  #
  # Returns the host and port for container +name+ on port +port+. Fails
  # if container is not running or the specified port is not exposed.
  #
  # Command reference: {docker port
  # }[https://docs.docker.com/reference/commandline/cli/#port]
  def docker_port(port, name = nil)
    name ||= docker_container_name

    docker :port, name, port
  end

  # call-seq:
  #   docker_url(port, name) -> aString
  #
  # Returns the HTTP URL for container +name+ on port +port+ (see
  # #docker_port).
  def docker_url(port, name = nil)
    "http://#{docker_port(port, name)}"
  end

  # call-seq:
  #   docker_ready(host_with_port[, path]) -> true or false
  #
  # Argument +host_with_port+ must be of the form <tt>host:port</tt>, as
  # returned by #docker_port, or an array of host and port.
  #
  # Returns +true+ if and when the TCP port is available on the host and,
  # if +path+ is given, a HTTP request for +path+ is successful.
  #
  # Returns +false+ if the port and the path haven't become available after
  # 30 attempts each. Sleeps for 0.1 seconds inbetween attempts.
  def docker_ready(host_with_port, path = nil, attempts = 30, sleep = 0.1)
    host, port = host_with_port.is_a?(Array) ?
      host_with_port : host_with_port.split(':')

    docker_socket_ready(host, port, attempts, sleep) &&
      (!path || docker_http_ready(host, port, path, attempts, sleep))
  end

  # call-seq:
  #   docker_start(name, image)
  #
  # Starts container +name+ from image +image+. This will fail if a
  # container with that name is already running. Use #docker_start!
  # in case you want to unconditionally start the container.
  #
  # Runs the container detached and with all exposed ports published.
  #
  # Command reference: {docker run
  # }[https://docs.docker.com/reference/commandline/cli/#run]
  def docker_start(name = nil, image = nil)
    name  ||= docker_container_name
    image ||= docker_image_name

    docker %W[run -d -P --name #{name} #{image}]
  end

  # call-seq:
  #   docker_start!(name, image)
  #   docker_start!(name, image) { |name, image| ... }
  #
  # Unconditionally starts container +name+ from image +image+.
  #
  # If the container is already running, it's restarted (see #docker_restart).
  # Otherwise, it's started (see #docker_start) and its +name+ and +image+ are
  # yielded to the block if given.
  def docker_start!(name = nil, image = nil)
    name  ||= docker_container_name
    image ||= docker_image_name

    docker_restart(name) || docker_start(name, image).tap {
      yield name, image if block_given?
    }
  end

  # call-seq:
  #   docker_stop(name)
  #
  # Stops container +name+.
  #
  # Command reference: {docker stop
  # }[https://docs.docker.com/reference/commandline/cli/#stop]
  def docker_stop(name = nil, _ = nil)
    name ||= docker_container_name

    docker %W[stop #{name}], ignore_errors: true
  end

  # call-seq:
  #   docker_restart(name)
  #
  # Restarts container +name+ by stopping (see #docker_stop) and then
  # starting it.
  #
  # Command reference: {docker start
  # }[https://docs.docker.com/reference/commandline/cli/#start]
  def docker_restart(name = nil, _ = nil)
    name ||= docker_container_name

    docker_stop name
    docker %W[start #{name}]
  end

  # call-seq:
  #   docker_clean(name)
  #
  # Stops and then removes container +name+, including associated volumes.
  #
  # Command reference: {docker rm
  # }[https://docs.docker.com/reference/commandline/cli/#rm]
  def docker_clean(name = nil, _ = nil)
    name ||= docker_container_name

    docker_stop name
    docker %W[rm -v -f #{name}], ignore_errors: true
  end

  # call-seq:
  #   docker_clobber(name, image)
  #
  # Removes container +name+ (see #docker_clean) as well as image +image+.
  #
  # Command reference: {docker rmi
  # }[https://docs.docker.com/reference/commandline/cli/#rmi]
  def docker_clobber(name = nil, image = nil)
    name  ||= docker_container_name
    image ||= docker_image_name

    docker_clean name
    docker %W[rmi #{image}], ignore_errors: true
  end

  # call-seq:
  #   docker_reset(name, image)
  #
  # Resets container +name+ by removing (see #docker_clean) and then
  # starting (see #docker_start) it from image +image+.
  def docker_reset(name = nil, image = nil)
    docker_clean(name)
    docker_start(name, image)
  end

  private

  # Placeholder for default container name; must be implemented by
  # utilizing class.
  def docker_container_name
    raise ArgumentError, 'container name missing', caller(1)
  end

  # Placeholder for default image name; must be implemented by
  # utilizing class.
  def docker_image_name
    raise ArgumentError, 'image name missing', caller(1)
  end

  # Executes the command in a subprocess and returns its output as a
  # string, or +nil+ if output is empty; override for different behaviour.
  def docker_pipe(*args)
    res = IO.popen(args, &:read).chomp
    res unless res.empty?
  end

  # Executes the command in a subshell; override for different behaviour.
  def docker_system(*args)
    system(*args)
  end

  # Simply aborts; override for different behaviour.
  def docker_fail(*args)
    abort
  end

  # Checks TCP connection.
  def docker_socket_ready(host, port, attempts, sleep)
    TCPSocket.new(host, port).close
    true
  rescue Errno::ECONNREFUSED
    return false unless docker_ready_sleep(sleep, attempts -= 1)
    retry
  end

  # Checks HTTP connection.
  def docker_http_ready(host, port, path, attempts, sleep)
    loop {
      begin
        break if Net::HTTP.get_response(host, path, port).is_a?(Net::HTTPSuccess)
      rescue Errno::ECONNRESET, EOFError => err
        return false unless docker_ready_sleep(sleep, attempts -= 1)
        retry
      end

      return false unless docker_ready_sleep(sleep, attempts -= 1)
    }

    true
  end

  # Sleeps unless out of attempts.
  def docker_ready_sleep(sleep, attempts)
    sleep(sleep) unless attempts.zero?
  end

end

require_relative 'docker_helper/version'
require_relative 'docker_helper/proxy'
