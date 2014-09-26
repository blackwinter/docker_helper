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

module DockerHelper

  class Pool

    DEFAULT_SIZE = 2

    DEFAULT_BASENAME = 'docker_helper'

    def initialize(size = nil, basename = nil, docker = nil)
      @docker, @previous_name, @basename =
        docker ||= DockerHelper.proxy, nil,
        basename ||= self.class::DEFAULT_BASENAME

      yield self if block_given?

      @pool = Array.new(size ||= self.class::DEFAULT_SIZE) { |i|
        spawn_thread("#{basename}-#{$$}-#{i}")
      }

      extend(SinglePool) if size == 1
    end

    attr_accessor :image, :port, :path

    def fetch_url(name = @previous_name)
      docker.url(port, @previous_name = fetch(name)) + path.to_s
    end

    def fetch(name = @previous_name)
      pool.shift.tap { reclaim(name) }.value
    end

    def clean(name = @previous_name)
      pool.map { |t| clean_thread(t.value) }.tap { |clean|
        clean << clean_thread(name) if name
      }.each(&:join)
    end

    def inspect
      '#<%s:0x%x %s@%d>' % [self.class, object_id, basename, pool.size]
    end

    private

    attr_reader :docker, :basename, :pool

    def spawn_thread(name, clean = false)
      Thread.new {
        docker.clean(name) if clean
        docker.start(name, image) if image
        docker.ready(docker.port(port, name), path) if port

        name
      }
    end

    def clean_thread(name)
      Thread.new { docker.clean(name) }
    end

    def reclaim(name)
      pool << spawn_thread(name, true) if name
    end

    module SinglePool

      def fetch(name = @previous_name)
        name || !block_given? ? super : yield(new_name = super)
      ensure
        reclaim(new_name)
      end

    end

  end

end
