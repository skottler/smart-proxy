#
# to start sidekiq: sidekiq -r ./lib/proxy/mcollective.rb -C config/sidekiq.yml -L logs/sidekiq.log
# to kick off an async job: curl -X POST -d {} http://localhost:8443/mcollective/<endpoint>
# to check status: curl -X GET http://localhost:8443/tasks/94b356ad3934a5b6ab0f7caa (use url returned from the previous command)
#

$LOAD_PATH.unshift *Dir["#{File.dirname(__FILE__)}/../../lib"]

require "proxy/settings"
require 'mcollective'
require 'sidekiq'
require 'connection_pool'
require 'rest_client'

module Proxy
  module ForemanCallbacks
    SETTINGS = Settings.load_from_file(Pathname.new(__FILE__).join("..", "..", "..", "config", "settings.yml"))

    CONNECT_PARAMS = {:timeout => 60, :open_timeout => 10}
    CONNECT_PARAMS.merge!(:user => SETTINGS.mco_user, :password => SETTINGS.mco_password) if SETTINGS.mco_user && SETTINGS.mco_password

    def rest_client
      ::RestClient::Resource.new(SETTINGS.mcollective_callback_url, CONNECT_PARAMS)
    end

    def task_status_callback(status, result)
      # rest_client["command_statuses/#{jid}"].put({:command_status => {:status => status, :result => result}}.to_json, :content_type => 'application/json', :accept => 'application/json;version=2')
    end
  end

  class BaseAsyncWorker
    include ::Sidekiq::Worker
    include ::MCollective::RPC
    include ::Proxy::ForemanCallbacks

    class << self
      attr_accessor :on_perform_blk
    end

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

    def perform(payload='', filters = [])
      c = client
      filters.each do |f|
        unless (cmd = hash_to_filter(f)).empty?
          c.send(*cmd)
        end
      end

      result = self.class.on_perform_blk.call(c, payload) unless self.class.on_perform_blk == nil

      task_status_callback("success", result)
    ensure
      c.reset_filter
    end

    def hash_to_filter(f_hash)
      case f_hash.keys.first
      when 'identity'
        [:identity_filter, f_hash.values.first]
      when 'class'
        [:class_filter, f_hash.values.first]
      when 'fact'
        [:fact_filter, f_hash.values.first]
      else
        # support for agent_filter and compound_filter
      end
    end

    def self.on_perform(&blk)
      self.on_perform_blk = blk
    end

    sidekiq_retries_exhausted do |msg|
      task_status_callback("failure", :error => msg['error_message'])
    end
  end

  module MCollective
    include ::MCollective::RPC

    module Agent
      class List < ::Proxy::BaseAsyncWorker
        def client
          super("rpcutil")
        end

        on_perform do |client, payload|
          agents = []
          client.agent_inventory.each do |agent|
            agent[:data][:agents].each do |item|
              agents << item[:agent]
            end
          end
          agents.uniq
        end
      end

      class Fields < ::Proxy::BaseAsyncWorker
        def initialize(agent)
          @agent = agent
        end

        def client
          super(@agent)
        end

        on_perform do |client, payload|
          client.self()
        end
      end
    end

    module Package
      class Install < ::Proxy::BaseAsyncWorker
        def client
          super("package")
        end

        on_perform do |client, package|
          client.install(:package => package)
        end
      end

      class Uninstall < ::Proxy::BaseAsyncWorker
        def client
          super("package")
        end

        on_perform do |client, package|
          client.uninstall(:package => package)
        end
      end
    end

    module Service
      class Status < ::Proxy::BaseAsyncWorker
        def client
          super("service")
        end

        on_perform do |client, service|
          client.status(:service => service)
        end
      end

      class Start < ::Proxy::BaseAsyncWorker
        def client
          super("service")
        end

        on_perform do |client, service|
          client.start(:service => service)
        end
      end

      class Stop < ::Proxy::BaseAsyncWorker
        def client
          super("service")
        end

        on_perform do |client, service|
          client.stop(:service => service)
        end
      end
    end

    module Util
      class Ping < ::Proxy::BaseAsyncWorker
        def client
          super("rpcutil")
        end

        on_perform do |client, notused|
          client.ping
        end
      end
    end
  end
end
