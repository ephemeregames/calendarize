class EventsController < ApplicationController

  def create

    @event = Event.new(params[:event])

    @event.save

    redirect_to controller: :welcome, action: :index
  end

end