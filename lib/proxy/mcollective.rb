require 'proxy/log'

module Proxy::MCollective
  extend Proxy::Log
  extend Proxy::Util

  class << self
    include MCollective::RPC
    def initialize
      @client = rpcclient("package")
      @client.progress = false
    end

    def install(package)
      @client.install(:package => package)
    end

    def uninstall(package)
      @client.uninstall(:package => package)
    end

    def disconnect
      @client.disconnect
    end
  end
end
