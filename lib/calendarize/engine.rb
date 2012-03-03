module Calendarize

  class Engine < ::Rails::Engine

    initializer 'Add Calendarize helpers to controller' do
      ActionController::Base.send :extend, CalendarizeHelper::Controller
    end

  end

end
