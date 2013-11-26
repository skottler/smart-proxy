# Rack configuration for the sidekiq web UI. It'll be listening on port 3000.
#
# Run `bundle exec rackup extra/sidekiq.ru` to start the app.
#
require 'sidekiq'

Sidekiq.configure_client do |config|
  config.redis = { :size => 1 }
end

require 'sidekiq/web'
run Sidekiq::Web
