class SmartProxy
  before do
    content_type :json
  end

  get "/tasks/:id" do
    begin
      Sidekiq.redis {|conn| conn.get("job:#{params[:id]}") }
    rescue Exception => e
      log_halt 400, e
    end
  end
end
