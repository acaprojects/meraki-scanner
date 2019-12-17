# Application dependencies
require "action-controller"
require "active-model"

# Logging configuration
ActionController::Logger.add_tag request_id
ActionController::Logger.add_tag client_ip

# Default log levels
running_in_production = ENV["SG_ENV"]? == "production"
logger = ActionController::Base.settings.logger
logger.level = running_in_production ? Logger::INFO : Logger::DEBUG

# Filter out sensitive params that shouldn't be logged
filter_params = [] of String
keeps_headers = ["X-Request-ID"]

# Application code
require "./controllers/application"
require "./controllers/*"
require "./models/*"

# Server required after application controllers
require "action-controller/server"

# Add handlers that should run before your application
ActionController::Server.before(
  ActionController::ErrorHandler.new(!running_in_production, keeps_headers),
  ActionController::LogHandler.new(filter_params),
  HTTP::CompressHandler.new
)

# Configure session cookies
# NOTE:: Change these from defaults
ActionController::Session.configure do |settings|
  settings.key = ENV["COOKIE_SESSION_KEY"]? || "aca_meraki_location"
  settings.secret = ENV["COOKIE_SESSION_SECRET"]? || "4f74c0b358d5bab4000dd3c75465dc2c"
  # HTTPS only:
  settings.secure = ENV["SG_ENV"]? == "production"
end

APP_NAME = "ACA Meraki"
VERSION  = "1.1.0"
