#
# to start sidekiq: sidekiq -r ./lib/proxy/mcollective.rb -L logs/sidekiq.log
# to kick off an async job: curl -X POST -d {} http://localhost:8443/mcollective/test/blahblah
# to check status: curl -X GET http://localhost:8443/tasks/94b356ad3934a5b6ab0f7caa (use url returned from the previous command)
#
require 'mcollective'
require 'sidekiq'
require 'connection_pool'

module Proxy
  class Trackable
    include ::Sidekiq::Worker
    include ::MCollective::RPC

    STARTED = "started"
    FINISHED = "finished"
    FAILED = "failed"
    RETRYING = "retrying"

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

    def save_state(state, result = {})
      Sidekiq.redis {|conn| conn.set("job:#{jid}", {'state' => state, 'result' => result}.to_json)}
    end

    def perform(payload='')
      save_state(STARTED)

      result = do_stuff(payload)

      save_state(FINISHED, result.to_json)
    rescue Exception => e
      save_state(RETRYING, e.message)
      raise e
    end

    sidekiq_retries_exhausted do |msg|
      save_state(FAILED, msg['error_message'])
    end
  end

  module MCollective
    include ::MCollective::RPC

    module Agent
      class List < ::Proxy::Trackable
        def client
          super("rpcutil")
        end

        def do_stuff(payload)
          client.agent_inventory()
        end
      end
    end

    module Package
      class Install < ::Proxy::Trackable
        def client
          super("package")
        end

        def perform(package)
          client.install(:package => package)
        end
      end

      class Uninstall < ::Proxy::Trackable
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

    class Util < ::Proxy::Trackable
      def client
        super("rpcutil")
      end

      def ping
        client.ping
      end
    end
  end
end
