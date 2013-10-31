#
# to start sidekiq: sidekiq -r ./lib/proxy/mcollective.rb -C config/sidekiq.yml -L logs/sidekiq.log
# to kick off an async job: curl -X POST -d {} http://localhost:8443/mcollective/<endpoint>
# to check status: curl -X GET http://localhost:8443/tasks/94b356ad3934a5b6ab0f7caa (use url returned from the previous command)
#
require 'mcollective'
require 'sidekiq'
require 'connection_pool'
require 'rest_client'

module Proxy
  module ForemanCallbacks
    CONNECT_PARAMS = {:timeout => 60, :open_timeout => 10}
    
    def rest_client
      ::RestClient::Resource.new("http://localhost:3000/", CONNECT_PARAMS)
    end

    def task_status_callback(status, result)
      rest_client["command_statuses/#{jid}"].put({:command_status => {:status => status, :result => result}}.to_json, :content_type => 'application/json', :accept => 'application/json;version=2')
    end
  end

  class BaseAsyncWorker
    include ::Sidekiq::Worker
    include ::MCollective::RPC
    include ::Proxy::ForemanCallbacks

    # Create a connection pool that's n + 1 where n is the number of workers.
    def pool(name)
      ConnectionPool.new(:size => 25, :timeout => 2) {
        rpcclient(name) { |c| c.progress = false; c }
      }
    end

    def client(name)
      pool(name).with do |rpc|
        return rpc
      end
    end

    def disconnect
      client.disconnect if @client
    end

    def perform(payload='')
      result = do_stuff(payload)
      task_status_callback("success", result)
    end

    sidekiq_retries_exhausted do |msg|
      task_status_callback("failure", :error => msg['error_message'])
    end
  end

  module MCollective
    include ::MCollective::RPC

    module Test
      class Blah < ::Proxy::BaseAsyncWorker
        def do_stuff(payload)
          "echo #{payload}"
        end
      end
    end

    module Agent
      class List < ::Proxy::BaseAsyncWorker
        def client
          super("rpcutil")
        end

        def do_stuff(payload)
          client.agent_inventory()
        end
      end
    end

    module Package
      class Install < ::Proxy::BaseAsyncWorker
        def client
          super("package")
        end

        def perform(package)
          client.install(:package => package)
        end
      end

      class Uninstall < ::Proxy::BaseAsyncWorker
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

    class Util < ::Proxy::BaseAsyncWorker
      def client
        super("rpcutil")
      end

      def ping
        client.ping
      end
    end
  end
end
