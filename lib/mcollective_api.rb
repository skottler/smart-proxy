class SmartProxy
  before do
    content_type :json
  end

  post "/mcollective/agents" do
    begin
      jid = Sidekiq::Client.push('class' => 'Proxy::MCollective::Agent::List', 'args' => [])
      status 202
      content_type :text
      body "/tasks/#{jid}"
    rescue Exception => e
      log_halt 400, e
    end
  end

  post "/mcollective/test/:name" do
    begin
      jid = Sidekiq::Client.push('class' => 'Proxy::MCollective::Test::TestCommand', 'args' => [params[:name]])
      status 202
      content_type :text
      body "/tasks/#{jid}"
    rescue Exception => e
      log_halt 400, e
    end
  end

  post "/mcollective/packages/:name" do
    begin
      Sidekiq::Client.push('class' => 'Proxy::MCollective::Package::Install', 'args' => [params[:name]])
    rescue Exception => e
      log_halt 400, e
    end
  end

  delete "/mcollective/packages/:name" do
    begin
      Sidekiq::Client.push('class' => 'Proxy::MCollective::Package::Uninstall', 'args' => [params[:name]])
    rescue Exception => e
      log_halt 400, e
    end
  end

  get "/mcollective/services/:name" do
    begin
      Sidekiq::Client.push('class' => 'Proxy::MCollective::Service::Status', 'args' => [params[:name]])
    rescue Exception => e
      log_halt 400, e
    end
  end

  post "/mcollective/services/:name/start" do
    begin
      Sidekiq::Client.push('class' => 'Proxy::MCollective::Service::Start', 'args' => [params[:name]])
    rescue Exception => e
      log_halt 400, e
    end
  end

  post "/mcollective/services/:name/stop" do
    begin
      Sidekiq::Client.push('class' => 'Proxy::MCollective::Service::Stop', 'args' => [params[:name]])
    rescue Exception => e
      log_halt 400, e
    end
  end

  get "/mcollective/ping" do
    begin
      Sidekiq::Client.push('class' => 'Proxy::MCollective::Util::Ping', 'args' => [])
    rescue Exception => e
      log_halt 400, e
    end
  end
end
