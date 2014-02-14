require 'celluloid'
require 'redis'
require 'rest_client'

module Proxy
  class McollectiveResultsPublisher
    include Proxy::Log
    include Celluloid

    SETTINGS = Settings.load_from_file(Pathname.new(__FILE__).join("..", "..", "..", "config", "settings.yml"))
    CONNECT_PARAMS = {:timeout => 60, :open_timeout => 10}
    CONNECT_PARAMS.merge!(:user => SETTINGS.mcollective_user, :password => SETTINGS.mcollective_password) if SETTINGS.mco_user && SETTINGS.mco_password

    def initialize
      super
      @redis = Redis.new
    end

    def rest_client
      ::RestClient::Resource.new(SETTINGS.mcollective_callback_url, CONNECT_PARAMS)
    end

    def run
      retries = 0
      loop do
        begin
          request_ids = @redis.zrangebyscore('MCO-RESULTS', (Time.now.utc - 25).to_i, Time.now.utc.to_i)
          request_ids.each do |request_id|
            non_parsed = @redis.lrange(request_id, 0, -1)
            parsed = non_parsed.collect {|json_string| JSON.parse(json_string)}
            status_callback(request_id, parsed)
            @redis.zrem('MCO-RESULTS', request_id)
          end
          retries = 0
          sleep 1
        rescue ::RestClient::Exception, ::Redis::CannotConnectError, ::Redis::ConnectionError, ::Redis::TimeoutError, ::Redis::CommandError => e
          retries += 1
          logger.error("MCO: Error when publishing results to foreman: #{e}. Retrying in 10s")
          sleep 10
        end
      end
    end

    def status_callback(jid, result)
      rest_client["command_statuses/#{jid}"].put({:command_status => result}.to_json, :content_type => 'application/json', :accept => 'application/json;version=2')
    end
  end
end