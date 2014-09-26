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

  # Generic proxy class that allows to call prefixed methods with or without
  # that prefix via #method_missing.

  class Proxy

    DEFAULT_PREFIX = 'docker'

    def initialize(prefix = nil)
      self.proxy_prefix = prefix || self.class::DEFAULT_PREFIX
    end

    attr_accessor :proxy_prefix

    def method_missing(method, *args, &block)
      respond_to_missing?(method) ?
        send(prefix_method(method), *args, &block) : super
    end

    def respond_to_missing?(method, _ = false)
      respond_to?(prefix_method(method))
    end

    private

    def prefix_method(method)
      "#{proxy_prefix}_#{method}"
    end

  end

end
