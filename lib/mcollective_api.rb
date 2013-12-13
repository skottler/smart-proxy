class SmartProxy
  before do
    content_type :json
  end

  helpers do
    def enqueue_job(klass, args=[])
      begin
        jid = Sidekiq::Client.push('class' => klass, 'args' => args)
        status 202
        content_type :text
        body "/tasks/#{jid}"
      rescue Exception => e
        log_halt 400, e
      end
    end
  end

  post "/mcollective/agents" do
    enqueue_job('Proxy::MCollective::Agent::List')
  end

  post "/mcollective/agents/:name" do
    enqueue_job('Proxy::MCollective::Agent::Info')
  end

  post "/mcollective/agents/:name/fields" do
    enqueue_job('Proxy::MCollective::Agent::Fields', [params[:name]])
  end

  post "/mcollective/packages/:name" do
    enqueue_job('Proxy::MCollective::Package::Install')
  end

  delete "/mcollective/packages/:name" do
    enqueue_job('Proxy::MCollective::Package::Uninstall', [params[:name], JSON.parse(params[:filters])])
  end

  get "/mcollective/services/:name" do
    enqueue_job('Proxy::MCollective::Service::Status', [params[:name], JSON.parse(params[:filters])])
  end

  post "/mcollective/services/:name/start" do
    enqueue_job('Proxy::MCollective::Service::Start', [params[:name], JSON.parse(params[:filters])])
  end

  post "/mcollective/services/:name/stop" do
    enqueue_job('Proxy::MCollective::Service::Stop', [params[:name], JSON.parse(params[:filters])])
  end

  post "/mcollective/puppet/runonce" do
    enqueue_job('Proxy::MCollective::Puppet::RunOnce', [nil, JSON.parse(params[:filters])])
  end

  post "/mcollective/puppet/start" do
    enqueue_job('Proxy::MCollective::Puppet::Start', [nil, JSON.parse(params[:filters])])
  end

  post "/mcollective/puppet/stop" do
    enqueue_job('Proxy::MCollective::Puppet::Stop', [nil, JSON.parse(params[:filters])])
  end

  get "/mcollective/ping" do
    enqueue_job('Proxy::MCollective::Util::Ping', [nil, JSON.parse(params[:filters])])
  end
end
