require 'celluloid'
require 'mcollective'
require 'redis'

module Proxy
  class McollectiveResultsCollector
    include Proxy::Log
    include Celluloid

    def initialize
      super
      ::MCollective::Applications.load_config
      ::MCollective::PluginManager["security_plugin"].initiated_by = :client

      @mco_connector = ::MCollective::PluginManager["connector_plugin"]
      @mco_connector.connect
      @mco_connector.connection.subscribe("/queue/mcollective.smart_proxy_results_collector")

      @redis = Redis.new
    end

    def run
      loop do
        work = @mco_connector.receive
        work.type = :reply
        work.decode!
        result = work.payload

        begin
          @redis.multi do
            @redis.rpush(result[:requestid], result.to_json)
            @redis.zadd('MCO-RESULTS', Time.now.utc.to_i, result[:requestid])
          end
        rescue ::Redis::BaseError => e
          logger.error("MCO: Error when persisting mco results in redis: #{e}. Retrying in 10s")
          sleep 10
          retry
        end
      end
    end
  end
end