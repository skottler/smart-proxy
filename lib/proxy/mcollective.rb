require 'proxy/log'

module Proxy::Mcollective
  class RPCClientBase
    include MCollective::RPC
    extend Proxy::Log
    extend Proxy::Util

    def client(aname)
      @client ||= rpcclient(aname) { |c| c.progress = false; c }
    end

    def disconnect
      client.disconnect unless @client == nil
    end
  end

  class Package < RPCClientBase
    def client
      super("package")
    end

    def install(package)
      client.install(:package => package)
    end

    def uninstall(package)
      client.uninstall(:package => package)
    end

  end

  class Service < RPCClientBase
    def client
      super("service")
    end

    def status(aservice)
      @client.status(:service => aservice)
    end

    def start(aservice)
      @client.start(:service => aservice)
    end

    def stop(aservice)
      @client.stop(:service => aservice)
    end
  end

  class Util < RPCClientBase
    def client
      super("rpcutil")
    end

    def ping
      client.ping
    end
  end
end
