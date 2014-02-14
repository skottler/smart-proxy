require 'proxy/mcollective_proxy'
require 'proxy/mcollective_results_collector'
require 'proxy/mcollective_results_publisher'

class Proxy::McoCollectorSupervisor < ::Celluloid::SupervisionGroup
  supervise Proxy::McollectiveResultsCollector, :as => :mco_results_collector

  def restart_actor(actor, reason)
    super
    sleep 10 #throttle restarts
    Celluloid::Actor[:mco_results_collector].async.run
  end
end

Proxy::McoCollectorSupervisor.run!
Celluloid::Actor[:mco_results_collector].async.run
Proxy::McollectiveResultsPublisher.new.async.run
