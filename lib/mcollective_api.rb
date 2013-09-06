class SmartProxy
  post "/mcollective/package/:name" do
    begin
      Proxy::MCollective.install(params[:name])
    rescue Exception => e
      log_halt 400, e
    end
  end

  delete "/mcollective/package/:name" do
    begin
      Proxy::MCollective.uninstall(params[:name])
    rescue Exception => e
      log_halt 400, e
    end
  end

  # TODO: figure out how to make service management more RESTful
  post "/mcollective/service/:name" do
    raise NotImplementedError.new
  end

  delete "/mcollective/service/:name" do
    raise NotImplementedError.new
  end
end
