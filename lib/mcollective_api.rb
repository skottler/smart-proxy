class SmartProxy
  before do
    content_type :json
  end

  helpers do
    def exec_mco_command(clazz, payload, filters=[])
      begin
        jid = clazz.new.perform(payload, filters)
        status 202
        content_type :text
        body "/tasks/#{jid}"
      rescue Exception => e
        log_halt 400, e
      end
    end
  end

  post "/mcollective/agents" do
    exec_mco_command(Proxy::MCollective::Agent::List)
  end

  post "/mcollective/agents/:name" do
    exec_mco_command(Proxy::MCollective::Agent::Info)
  end

  post "/mcollective/agents/:name/fields" do
    exec_mco_command(Proxy::MCollective::Agent::Fields, params[:name])
  end

  post "/mcollective/packages/:name" do
    exec_mco_command(Proxy::MCollective::Package::Install, params[:name], JSON.parse(params[:filters]))
  end

  delete "/mcollective/packages/:name" do
    exec_mco_command(Proxy::MCollective::Package::Uninstall, params[:name], JSON.parse(params[:filters]))
  end

  get "/mcollective/services/:name" do
    exec_mco_command(Proxy::MCollective::Service::Status, params[:name], JSON.parse(params[:filters]))
  end

  post "/mcollective/services/:name/start" do
    exec_mco_command(Proxy::MCollective::Service::Start, params[:name], JSON.parse(params[:filters]))
  end

  post "/mcollective/services/:name/stop" do
    exec_mco_command(Proxy::MCollective::Service::Stop, params[:name], JSON.parse(params[:filters]))
  end

  post "/mcollective/puppet/runonce" do
    exec_mco_command(Proxy::MCollective::Puppet::RunOnce, nil, JSON.parse(params[:filters]))
  end

  post "/mcollective/puppet/enable" do
    exec_mco_command(Proxy::MCollective::Puppet::Enable, nil, JSON.parse(params[:filters]))
  end

  post "/mcollective/puppet/disable" do
    exec_mco_command(Proxy::MCollective::Puppet::Disable, nil, JSON.parse(params[:filters]))
  end

  get "/mcollective/ping" do
    exec_mco_command(Proxy::MCollective::Util::Ping, nil, JSON.parse(params[:filters]))
  end
end
