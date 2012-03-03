require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require
require 'calendarize'

module Dummy
  class Application < Rails::Application
    config.encoding = "utf-8"
    config.time_zone = 'Eastern Time (US & Canada)'
    config.filter_parameters += [:password]
    config.assets.enabled = true
    config.assets.version = '1.0'
  end
end

