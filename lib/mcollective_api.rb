class SmartProxy
  post "/mcollective/packages/:name" do
    begin
      Proxy::MCollective::Package.new.install(params[:name])
    rescue Exception => e
      log_halt 400, e
    end
  end

  delete "/mcollective/packages/:name" do
    begin
      Proxy::MCollective::Package.new.uninstall(params[:name])
    rescue Exception => e
      log_halt 400, e
    end
  end

  get "/mcollective/services/:name" do
    begin
      Proxy::MCollective::Service.new.status(params[:name])
    rescue Exception => e
      log_halt 400, e
    end
  end

  post "/mcollective/services/:name/start" do
    begin
      Proxy::MCollective::Service.new.start(params[:name])
    rescue Exception => e
      log_halt 400, e
    end
  end

  post "/mcollective/services/:name/stop" do
    begin
      Proxy::MCollective::Service.new.stop(params[:name])
    rescue Exception => e
      log_halt 400, e
    end
  end

  get "/mcollective/ping" do
    begin
      Proxy::MCollective::Util.new.ping()
    rescue Exception => e
      log_halt 400, e
    end
  end
end
