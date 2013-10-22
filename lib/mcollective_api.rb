class SmartProxy
  before do
    content_type :json
  end

  post "/mcollective/test/:name" do
    begin
      Sidekiq::Client.push('class' => 'Proxy::MCollective::Test::TestCommand', 'args' => [params[:name]])
    rescue Exception => e
      log_halt 400, e
    end
  end
    
  post "/mcollective/packages/:name" do
    begin
      Sidekiq::Client.push('class' => 'Proxy::MCollective::Package::Install', 'args' => [params[:name]])
#      Proxy::MCollective::Package.new.install(params[:name]).to_json
    rescue Exception => e
      log_halt 400, e
    end
  end

  delete "/mcollective/packages/:name" do
    begin
      Sidekiq::Client.push('class' => 'Proxy::MCollective::Package::Uninstall', 'args' => [params[:name]])
#      Proxy::MCollective::Package.new.uninstall(params[:name]).to_json
    rescue Exception => e
      log_halt 400, e
    end
  end

  get "/mcollective/services/:name" do
    begin
      Sidekiq::Client.push('class' => 'Proxy::MCollective::Service::Status', 'args' => [params[:name]])
#      Proxy::MCollective::Service.new.status(params[:name]).to_json
    rescue Exception => e
      log_halt 400, e
    end
  end

  post "/mcollective/services/:name/start" do
    begin
      Sidekiq::Client.push('class' => 'Proxy::MCollective::Service::Start', 'args' => [params[:name]])
#      Proxy::MCollective::Service.new.start(params[:name]).to_json
    rescue Exception => e
      log_halt 400, e
    end
  end

  post "/mcollective/services/:name/stop" do
    begin
      Sidekiq::Client.push('class' => 'Proxy::MCollective::Service::Stop', 'args' => [params[:name]])
#      Proxy::MCollective::Service.new.stop(params[:name]).to_json
    rescue Exception => e
      log_halt 400, e
    end
  end

  get "/mcollective/ping" do
    begin
      Sidekiq::Client.push('class' => 'Proxy::MCollective::Util::Ping', 'args' => [])
#      Proxy::MCollective::Util.new.ping().to_json
    rescue Exception => e
      log_halt 400, e
    end
  end
end
