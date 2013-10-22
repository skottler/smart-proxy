#
# to start sidekiq: sidekiq -r ./lib/proxy/mcollective.rb -L logs/sidekiq.log
#
require 'mcollective'
#require 'proxy/log'
require 'sidekiq'

module Proxy
  module MCollective
    
    class RPCClientBase
      include ::MCollective::RPC
      include ::Sidekiq::Worker
      #extend ::Proxy::Log
      #extend Proxy::Util

      def client(aname)
        @client ||= rpcclient(aname) { |c| c.progress = false; c }
      end

      def disconnect
        client.disconnect unless @client == nil
      end
    end

    module Test
      class TestCommand
        include ::Sidekiq::Worker
        
        def perform(payload)
          logger.info("!!!!!!!!!!!!!!!!! #{payload}")
        end
      end
    end

    module Package
      class Install < RPCClientBase
        def client
          super("package")
        end

        def perform(package)
          client.install(:package => package)
        end
      end
    
      class Uninstall < RPCClientBase
        def client
          super("package")
        end

        def perform(package)
          client.uninstall(:package => package)
        end
      end
    end

    module Service
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
end