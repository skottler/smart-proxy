require 'proxy/settings'
require 'mcollective'

module Proxy
  class BaseAsyncWorker
    include ::MCollective::RPC

    class << self
      attr_accessor :on_perform_blk
    end

    # Create a connection pool that's n + 1 where n is the number of workers.
    def pool(name)
      ConnectionPool.new(:size => 25, :timeout => 2) {
        rpcclient(name, {:flatten => true}) { |c| c.progress = false; c }
      }
    end

    def client(name)
      #pool(name).with do |rpc|
      #  return rpc
      #end
      r = rpcclient(name, {:flatten => true}) { |c| c.progress = false; c }
      r.reply_to = "/queue/mcollective.smart_proxy_results_collector"
      r
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
  end

  module MCollective
    include ::MCollective::RPC

    module Agent
      class List < ::Proxy::BaseAsyncWorker
        def client
          super("rpcutil")
        end

        on_perform do |client, payload|
          client.agent_inventory.each do |agent|
            agent[:data][:agents].each do |item|
              (agents ||= []) << item[:agent]
            end
          end
          agents.uniq
        end
      end

      class Fields < ::Proxy::BaseAsyncWorker
        include ::MCollective::DDL
        def client
          super('rpcutil')
        end

        on_perform do |client, name|
          client.agent_inventory.each do |host|
            host[:data][:agents].each do |agent|
              begin
                (@agent_discovery_info ||= []) << MCollective::DDL.new(agent[:name])
              rescue
                # there's no DDL for the agent
              end
            end
          end
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

    module Puppet
      class RunOnce < ::Proxy::BaseAsyncWorker
        def client
          super("puppet")
        end

        on_perform do |client, notused|
          client.runonce()
        end
      end

      class Enable < ::Proxy::BaseAsyncWorker
        def client
          super("puppet")
        end

        on_perform do |client, notused|
          client.enable()
        end
      end

      class Disable < ::Proxy::BaseAsyncWorker
        def client
          super("puppet")
        end

        on_perform do |client, notused|
          client.disable()
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
