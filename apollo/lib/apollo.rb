require 'celluloid'
require 'active_attr'
require 'cabin'

require 'apollo/version'
require 'apollo/container'

module Apollo
  class << self
    def logger
      @channel ||= Cabin::Channel.new
      @channel.subscribe(STDOUT)
      @channel
    end
  end
end

Celluloid.logger = Apollo.logger
