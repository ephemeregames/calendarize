module CalendarizeHelper

  # Creates a daily calendar for events
  #
  # Usage: daily_calendar day, events, [options] { |c| ... }
  #
  # Params
  # :day, Date, the day to display
  # :events, ?, the events to display. An event must responds to:
  #   - start_time: a TimeWithZone object (from ActiveRecord)
  #   - end_time: a TimeWithZone object (from ActiveRecord)
  #   - status: a string
  # :block |c|, is yield for every event placed so you can customize it's content. :c is the calendar, which have:
  #   - @event: the current event that is rendering
  #   - @is_all_day: if the current event is an all-day one
  #
  # Options
  # :unit, integer, the time unit in minutes between two rows, defaults to 60. Must be > 0.
  # :date_format, symbol, the format of the date to find at I18n.l('date.formats.date_format'), defaults to :long
  # :url, the url path to call for some actions (ex: previous day), some params will be appended, defaults to request.path
  # :id, integer, id of the calendar, default to one provided by this helper
  # :day_start, integer, when to start showing events on the calendar, in minutes, defaults to 0
  # :day_end, integer, when to stop showing events on the calendar, in minutes, defaults to 1440 (24 hours)
  # :verbose, boolean, show all the rows or only those with events, defaults to true
  # :unit_clicked_path, Array of 2 components: url, options, a link to follow when we click on the units on the left side
  # :cell_clicked_path, Array of 2 components: url, options, a link to follow when we click an empty spot on a row
  #
  def daily_calendar_for(*args, &block)
    DailyCalendarBuilder.new(self, *args).compute.render(&block)
  end

  alias_method :daily_calendar, :daily_calendar_for


  # Creates a weekly calendar for events
  #
  # Usage: weekly_calendar day, events, [options] { |c| ... }
  #
  # Params
  # :day, Date, the day to display. Will display the week that contains that day
  # :events, ?, the events to display. An event must responds to:
  #   - start_time: a TimeWithZone object (from ActiveRecord)
  #   - end_time: a TimeWithZone object (from ActiveRecord)
  #   - status: a string
  # :block |c|, is yield for every event placed so you can customize it's content. :c is the calendar, which have:
  #   - @event: the current event that is rendering
  #
  # Options
  # :unit, integer, the time unit in minutes between two rows, defaults to 60. Must be > 0.
  # :date_format, symbol, the format of the date to find at I18n.l('date.formats.date_format'), defaults to :long
  # :id, integer, id of the calendar, default to one provided by this helper
  # :week_start, Date::DAYS_INTO_WEEK.keys or string, the day to start the week, defaults to :monday
  # :week_end, Date::DAYS_INTO_WEEK.keys or string, the day to end the week, defaults to :sunday
  #
  def weekly_calendar_for(*args, &block)
    WeeklyCalendarBuilder.new(self, *args).compute.render(&block)
  end

  alias_method :weekly_calendar, :weekly_calendar_for


  # Creates a monthly calendar for events
  #
  # Usage: monthly_calendar day, events, [options] { |c| ... }
  #
  # Params
  # :day, Date, the day to display. Will display the month that contains that day
  # :events, ?, the events to display. An event must responds to:
  #   - start_time: a TimeWithZone object (from ActiveRecord)
  #   - end_time: a TimeWithZone object (from ActiveRecord)
  #   - status: a string
  # :block |c|, is yield for every event placed so you can customize it's content. :c is the calendar, which have:
  #   - @event: the current event that is rendering
  #
  # Options
  # :unit, integer, the time unit in minutes between two rows, defaults to 60. Must be > 0.
  # :date_format, symbol, the format of the date to find at I18n.l('date.formats.date_format'), defaults to :long
  # :id, integer, id of the calendar, default to one provided by this helper
  #
  def monthly_calendar_for(*args, &block)
    MonthlyCalendarBuilder.new(self, *args).compute.render(&block)
  end

  alias_method :monthly_calendar, :monthly_calendar_for


  # Returns the current params for a calendar
  # Used when you want to keep track of the calendar between two requests
  # Can be used with path helpers
  #
  # Usage: resource_path(calendar_current_params)
  #
  def calendar_current_params
    { calendar: @calendar.clone }
  end


  # An enum object that hold the possible scopes for a calendar
  # The scope can be used in a calendar view to know which calendar to show
  #
  class Scopes
    DAILY = 'daily'
    WEEKLY = 'weekly'
    MONTHLY = 'monthly'
  end


  # Methods used in an existing controller to get the params associated to a calendar and pass them to the view
  # Automatically included by the engine as a class helper
  # Right now it only supports one calendar per view but it should not be hard to throw some :uuid in the process
  #
  # Usage:
  #
  # class MyCalendarController < ApplicationController
  #   calendarize
  # end
  #
  module Controller

    def calendarize

      before_filter lambda {
        @calendar = { }

        # I hate time handling in RoR...
        # Time.zone.parse is prefered to DateTime.parse because it preserve the timezone

        if params[:calendar]
          @calendar[:date] = Time.zone.parse(params[:calendar][:date]).to_datetime
          @calendar[:verbose] = params[:calendar].has_key?(:verbose) ? params[:calendar][:verbose] == 'true' : true
          @calendar[:scope] = params[:calendar][:scope] || 'daily'
        else
          @calendar[:date] = DateTime.now.beginning_of_day
          @calendar[:verbose] = true
          @calendar[:scope] = 'daily'
        end
      }

    end

  end


  # Methods used in an ActiveRecord model to make it compatible with the library
  # Note: A model must respond to :start_time, :end_time (:datetime fields) and :status (string)
  #
  # Usage:
  #
  # class MyEventModel < ActiveRecord::Base
  #   acts_as_event
  # end
  #
  #
  # class MyEventsMigration < ActiveRecord::Migration
  #   def change
  #     create_table :my_events do |t|
  #       t.datetime :start_time
  #       t.datetime :end_time
  #       t.string :status
  #     end
  #   end
  # end
  #
  # I did not want to dictate how your event model should be; that's why you must
  # create your event model and your migration. However, once this is done, you
  # can use :acts_as_event to ease the process. It will add the scopes needed to
  # send the events to the calendars.
  #
  # Note: You can have an event model that is not persisted in your database.
  # As long as your model responds to the three methods :start_time, :end_time and :status,
  # you're OK. However, :acts_as_event won't help you in that case.
  #
  module Model

    module ActsAsEvent

      def acts_as_event
        scope :for_day, lambda { |date = nil| where('start_time >= ? AND start_time <= ?', date ? date : DateTime.now.beginning_of_day, date ? date.end_of_day : DateTime.now.end_of_day) }
        scope :for_week, lambda { |date = nil, week_start = :monday|
            where(
              'start_time >= ? AND start_time < ?',
              date ? date.to_time.beginning_of_week(week_start) : DateTime.now.beginning_of_week(week_start),
              date ? date.to_time.end_of_week(week_start) : DateTime.now.end_of_week(week_start)
            )
        }
        scope :for_month, lambda { |date = nil|
            where(
              'start_time >= ? AND start_time < ?',
              date ? date.to_time.beginning_of_month : DateTime.now.beginning_of_month,
              date ? date.to_time.end_of_month : DateTime.now.end_of_month
            )
        }
      end

    end


    class ActiveRecord::Base

      extend ActsAsEvent

    end

  end


  private

    # This proxy class is used when we pass an hash instead of an Event class
    class HashEvent

      def initialize(event)
        @event = event
      end

      def method_missing(method, *args, &block)
        @event.send(:[], method)
      end

    end

    # This class builds a calendar. It is used to build the daily and the weekly calendars
    class AbstractCalendarBuilder < ActionView::Base

      @@uuid = 100

      attr_reader :event, :is_all_day


      def initialize(view_context, *args)
        opts = args.extract_options!

        @view_context   = view_context

        @options = {
          unit: 60,
          date_format: :long,
          url: @view_context.request.path,
          verbose: true,
          day_start: 0,
          day_end: 1440,
          cell_clicked_path: nil
        }.merge!(opts)

        @day = args.shift || Date.today
        @events = args.shift || []
        @events = @events.map{ |e| HashEvent.new(e) } if @events.first.kind_of?(Hash)
        @event = nil # can be accessed by the passed block
        @is_all_day = false

        @@uuid += 1
      end


      def compute
        day_time = @day.to_datetime

        # Get the starting and the ending row of the calendar
        # :starting_row and :ending_row are in minutes so if :starting_row == 60
        # and the :unit == 60, that means one row equals 1 hour and we start the
        # rows at hour 1.
        @_starting_row = @options[:day_start] / @options[:unit]
        @_ending_row = @options[:day_end] / @options[:unit]

        # Get the rows (in :datetime)
        # The indexes will be used as :ids in the rendering
        @rows = (@_starting_row...@_ending_row).to_a
        @rows_hours = @rows.map { |r| day_time + r * @options[:unit] / 1440.0 }

        # Sort the events in ascending order of their :start_time
        # Note: not done in-place the first time so the user can re-use it's collection
        @events = @events.sort { |e1, e2| e1.start_time <=> e2.start_time }

        self
      end


      def render

      end


      protected

        # Get the row associated with the given time, in minutes
        def row(time_with_zone)
          (time_with_zone.to_datetime.hour * 60 + time_with_zone.to_datetime.min)
        end


        # Get the row associated with the given time, in :units
        def row_unit(time_with_zone)
          row(time_with_zone) / @options[:unit]
        end


        def to_query_params(options = {})
          {
            calendar: {
              date: Date.today,
              verbose: @options[:verbose],
              scope: @options[:scope]
            }.merge(options)
          }.to_query
        end

    end


    class DailyCalendarBuilder < AbstractCalendarBuilder

      def initialize(view_context, *args)

        opts = {
          id: "daily_calendar_#{@@uuid}",
          scope: 'daily',
          unit_clicked_path: nil
        }.merge!(args.extract_options!)

        args << opts

        super(view_context, *args)
      end


      def compute

        super

        # Partition the events between all-day and :not all-day events
        # Then, for the :not all-day events, put them in rows
        rows_events = {}
        @all_day_events, not_all_day_events = @events.partition { |e| e.end_time.to_date > @day }

        not_all_day_events.each do |e|
          row_unit = row_unit(e.start_time)

          if !rows_events.has_key?(row_unit)
            rows_events[row_unit] = [e]
          else
            rows_events[row_unit] << e
          end
        end

        # We remove the events that:
        # - start or end before the :starting_row
        # - start or end after the :ending_row
        rows_events.each_value { |r| r.reject! { |e| row_unit(e.start_time) >= @_ending_row || row_unit(e.start_time) < @_starting_row } }
        rows_events.each_value { |r| r.reject! { |e| row_unit(e.end_time)   >= @_ending_row || row_unit(e.end_time)   < @_starting_row } }

        # Sort each row by the starting time of the event, ascending order. If the starting time is the same, we
        # then sort by the ending time
        rows_events.each_value do |r|
          r.sort! do |e1, e2|
            if e1.start_time == e2.start_time
              e1.end_time <=> e2.end_time
            else
              e1.start_time <=> e2.start_time
            end
          end
        end

        # Put the events in columns, which give a tuple '[[row_start, row_end, column], event]' for the event
        # that will be used to output the calendar. The algorithm works like this:
        # - As we cycle in the rows (which contains events that start at the same :unit time), we create columns and
        #   we keep track of what we put in the columns
        # - When to decide in which column to put an event, we start from the column 0 and check the :end_time of the
        #   last event inserted in that column. If this :end_time is less than the :start_time of the event we want
        #   to insert, we have a candidate!
        columns = {}
        @placed_events = []

        rows_events.each do |i,v|
          v.each do |e|
            j = 0
            placed = false

            while (!placed) do
              if !columns.has_key?(j)
                columns[j] = [e]
                @placed_events << [[i, row_unit(e.end_time - 1) + 1, j], e] # i + ((e.end_time - e.start_time) / (60 * @options[:unit])).ceil
                placed = true
              elsif (row_unit(e.start_time) >= row_unit(columns[j].last.end_time - 1) + 1)
                columns[j] << e
                @placed_events << [[i, row_unit(e.end_time - 1) + 1, j], e]
                placed = true
              else
                j += 1
              end
            end
          end
        end

        # We make a list of all the rows to render
        # If we set the option :verbose to false, we only show the rows that have events
        occupied_rows = []
        @placed_events.each { |tuple| occupied_rows << (tuple[0][0]...tuple[0][1]).to_a }
        occupied_rows.flatten!
        occupied_rows.uniq!
        @rows_to_render_indexes = @options[:verbose] ? @rows.map.with_index { |x, i| i } : occupied_rows.map { |r| @rows.index(r) }

        self
      end


      def render(&block)
        content_tag(:div, class: 'daily_calendar', id: @options[:id], style: 'position: relative;') do

          tables = ''.html_safe

          # controls
          tables << content_tag(:table, id: 'controls', class: 'styled', style: 'width: 100%;') do
            content_tag(:thead) do
              content_tag(:tr) do
                content = ''.html_safe
                content << content_tag(:th, style: 'width: 33%;') { link_to(@options[:verbose] ? I18n.t('calendarize.daily_calendar.options.verbose', default: 'Compact') : I18n.t('calendarize.daily_calendar.options.not_verbose', default: 'Full'), @options[:url] + '?' + to_query_params({ date: @day.to_date, verbose: !@options[:verbose] })) }
                content << content_tag(:th, style: 'width: 33%;') { ("<input type='text' class='datepicker' value='" + I18n.l(@day.to_date, format: @options[:date_format]) + "' />").html_safe }
                content << content_tag(:th, style: 'width: 33%;') do
                  options = ''.html_safe
                  options << link_to(I18n.t('calendarize.daily_calendar.options.previous_day', default: 'Previous day'), @options[:url] + '?' +  to_query_params({ date: @day.yesterday.to_date }))
                  options << ' | '
                  options << link_to(I18n.t('calendarize.daily_calendar.options.today', default: 'Today'), @options[:url] + '?' + to_query_params)
                  options << ' | '
                  options << link_to(I18n.t('calendarize.daily_calendar.options.next_day', default: 'Next day'), @options[:url] + '?' + to_query_params({ date: @day.tomorrow.to_date }))
                  options
                end
                content
              end
            end
          end

          # all day events
          tables << content_tag(:table, id: 'all_day', class: 'styled', style: 'width: 100%;') do
            content = ''.html_safe
            content << content_tag(:thead) do
              content_tag(:tr) do
                content_tag(:th) { I18n.t('calendarize.daily_calendar.all_day_events', default: 'All day events') }
              end
            end

            content << content_tag(:tbody) do

              trs = ''.html_safe

              @all_day_events.each_index do |i|
                trs << content_tag(:tr) do
                  @event = @all_day_events[i]
                  @is_all_day = true
                  content_tag(:td, class: 'row_content', id: "row_content_#{i}") { @view_context.capture(self, &block) }
                end
              end

              trs
            end

            content
          end unless @all_day_events.empty?

          # normal events
          tables << content_tag(:table, id: 'not_all_day', class: 'styled', style: 'width: 100%;') do
            content = ''.html_safe
            content << content_tag(:thead) do
              content_tag(:tr) do
                header = ''.html_safe
                header << content_tag(:th, style: 'width: 40px;') { I18n.t('calendarize.daily_calendar.hours', default: 'Hours') }
                header << content_tag(:th) { }
                header
              end
            end

            content << content_tag(:tbody) do

              trs = ''.html_safe

              @rows_to_render_indexes.each do |i|
                trs << content_tag(:tr, class: 'row_unit', style: 'height: 60px;') do
                  tds = ''.html_safe

                  tds << content_tag(:td, class: 'row_header', id: "row_header_#{@rows[i]}", style: 'width: 40px; text-align: center') do
                    if @options[:unit_clicked_path].nil?
                      @rows_hours[i].strftime('%H:%M')
                    elsif @options[:unit_clicked_path].kind_of?(Array)
                      link_to(@rows_hours[i].strftime('%H:%M'), @options[:unit_clicked_path][0] + '?' +  { start_time: I18n.l(@rows_hours[i]) }.to_query, @options[:unit_clicked_path][1])
                    else
                      link_to(@rows_hours[i].strftime('%H:%M'), @options[:unit_clicked_path] + '?' +  { start_time: I18n.l(@rows_hours[i]) }.to_query)
                    end
                  end

                  tds << content_tag(:td, class: 'row_content', id: "row_content_#{@rows[i]}") do
                    if @options[:cell_clicked_path].nil?

                    elsif @options[:cell_clicked_path].kind_of?(Array)
                      link_to('', @options[:cell_clicked_path][0] + '?' +  { start_time: I18n.l(@rows_hours[i]) }.to_query, @options[:cell_clicked_path][1].merge({ style: 'display: block; width: 100%; height: 100%' }))
                    else
                      link_to('', @options[:cell_clicked_path] + '?' +  { start_time: I18n.l(@rows_hours[i]) }.to_query, style: 'display: block; width: 100%; height: 100%')
                    end
                  end

                  tds
                end
              end

              trs
            end

            content
          end

          # place the events at the end of the calendar
          # they will be placed at the right place on the calendar with some javascript magic
          tables << content_tag(:div, class: 'not_all_day_events') do

            events_div = ''.html_safe

            @placed_events.each do |e|
              @event = e[1]
              @is_all_day = false
              events_div << content_tag(:div, class: ['calendar_event', @event.status.underscore], data: { row_start: e[0][0], row_end: e[0][1], column: e[0][2] }, style: 'z-index: 1;') do
                content_tag(:div, class: 'content') { @view_context.capture(self, &block) }
              end
            end

            events_div
          end

          tables
        end
      end

    end


    class WeeklyCalendarBuilder < AbstractCalendarBuilder

      def initialize(view_context, *args)

        opts = {
          id: "weekly_calendar_#{@@uuid}",
          week_start: :monday,
          week_end: :sunday,
          scope: 'weekly'
        }.merge!(args.extract_options!)

        opts[:week_start] = opts[:week_start].to_sym
        opts[:week_end]   = opts[:week_end].to_sym

        args << opts

        super(view_context, *args)

        # We calculate the number of days between :week_start and :week_end
        ws = Date::DAYS_INTO_WEEK[@options[:week_start]]
        we = Date::DAYS_INTO_WEEK[@options[:week_end]]
        we += 7 if we <= ws

        @day_start = @day.beginning_of_week(@options[:week_start]).to_date
        @day_end = @day_start + (we - ws)

      end


      def compute

        super

        # We put events in rows
        @_rows_events = {}

        @events.each do |e|
          row_unit = row_unit(e.start_time)

          if !@_rows_events.has_key?(row_unit)
            @_rows_events[row_unit] = [e]
          else
            @_rows_events[row_unit] << e
          end
        end

        # We remove the events that:
        # - start or end before the :starting_row
        # - start or end after the :ending_row
        @_rows_events.each_value { |r| r.reject! { |e| row_unit(e.start_time) >= @_ending_row || row_unit(e.start_time) < @_starting_row } }
        @_rows_events.each_value { |r| r.reject! { |e| row_unit(e.end_time)   >= @_ending_row || row_unit(e.end_time)   < @_starting_row } }

        # Sort each row by the starting time of the event, ascending order. If the starting time is the same, we
        # then sort by the ending time
        @_rows_events.each_value do |r|
          r.sort! do |e1, e2|
            if e1.start_time == e2.start_time
              e1.end_time <=> e2.end_time
            else
              e1.start_time <=> e2.start_time
            end
          end
        end

        # We remove the events that are outside the days watched
        @_rows_events.each_value { |r| r.reject! { |e| e.start_time.to_date < @day_start || e.start_time.to_date > @day_end } }

        @days_shown = (@day_start..@day_end).to_a

        # Put the events in columns, which give a tuple '[[row, column, index], event]' for the event
        # that will be used to output the calendar. The :index is used to identify an event on a same
        # :row and :column
        @placed_events = []

        @_rows_events.each do |i, v|
          columns = {}
          v.each { |e| columns[column(e.start_time)] = 0 }

          v.each do |e|
            column = column(e.start_time)

            @placed_events << [[i, column, columns[column]], e]

            columns[column] += 1
          end
        end

        # We make a list of all the rows to render
        # If we set the option :verbose to false, we only show the rows that have events
        occupied_rows = []
        @placed_events.each { |tuple| occupied_rows << tuple[0][0] }
        occupied_rows.uniq!

        @rows_to_render_indexes = @options[:verbose] ? @rows.map.with_index { |x, i| i } : occupied_rows.map { |r| @rows.index(r) }

        self
      end


      def render(&block)
        content_tag(:div, class: 'weekly_calendar', id: @options[:id], style: 'position: relative;') do

          tables = ''.html_safe

          # controls
          tables << content_tag(:table, id: 'controls', class: 'styled', style: 'width: 100%;') do
            content_tag(:thead) do
              content_tag(:tr) do
                content = ''.html_safe
                content << content_tag(:th, style: 'width: 33%;') { link_to(@options[:verbose] ? I18n.t('calendarize.weekly_calendar.options.verbose', default: 'Compact') : I18n.t('calendarize.weekly_calendar.options.not_verbose', default: 'Full'), @options[:url] + '?' + to_query_params({ date: @day.to_date, verbose: !@options[:verbose] })) }
                content << content_tag(:th, style: 'width: 33%;') { (I18n.t('calendarize.weekly_calendar.week_of', default: 'Week of') + "<input type='text' class='datepicker' value='" + I18n.l(@day_start.to_date, format: @options[:date_format]) + "' />").html_safe }
                content << content_tag(:th, style: 'width: 33%;') do
                  options = ''.html_safe
                  options << link_to(I18n.t('calendarize.weekly_calendar.options.previous_week', default: 'Previous week'), @options[:url] + '?' +  to_query_params({ date: @day_start.prev_week(@options[:week_start]).to_date }))
                  options << ' | '
                  options << link_to(I18n.t('calendarize.weekly_calendar.options.current_week', default: 'This week'), @options[:url] + '?' + to_query_params)
                  options << ' | '
                  options << link_to(I18n.t('calendarize.weekly_calendar.options.next_week', default: 'Next week'), @options[:url] + '?' + to_query_params({ date: @day_end.next_week(@options[:week_start]).to_date }))
                  options
                end
                content
              end
            end
          end

          # normal events
          tables << content_tag(:table, id: 'not_all_day', class: 'styled', style: 'width: 100%;') do
            content = ''.html_safe
            content << content_tag(:thead) do
              content_tag(:tr) do
                header = ''.html_safe

                header << content_tag(:th, style: 'width: 40px;') { I18n.t('calendarize.weekly_calendar.hours', default: 'Hours') }

                @days_shown.each do |d|
                  header << content_tag(:th) {
                    link_to(I18n.l(d, format: @options[:date_format]), @options[:url] + '?' + to_query_params({ date: d, verbose: @options[:verbose], scope: CalendarizeHelper::Scopes::DAILY }))
                  }
                end

                header
              end
            end

            content << content_tag(:tbody) do

              trs = ''.html_safe

              @rows_to_render_indexes.each do |i|
                trs << content_tag(:tr, class: 'row_unit', data: { events_count: @_rows_events.include?(@rows[i]) ? @_rows_events[@rows[i]].map{ |e| column(e.start_time) }.group_by{ |i| i }.map{ |k, v| v.count }.max : 0 }) do
                  tds = ''.html_safe

                  tds << content_tag(:td, class: 'row_header', id: "row_header_#{@rows[i]}", style: 'width: 40px') { @rows_hours[i].strftime('%H:%M') }

                  @days_shown.each_index do |j|
                    tds << content_tag(:td, class: ["row_#{@rows[i]}", "column_#{j}"]) do
                      if @options[:cell_clicked_path].nil?

                      elsif @options[:cell_clicked_path].kind_of?(Array)
                        link_to('', @options[:cell_clicked_path][0] + '?' +  { start_time: I18n.l(@rows_hours[i] + (j - 2).days)}.to_query, @options[:cell_clicked_path][1].merge({ style: 'display: block; width: 100%; height: 100%' }))
                      else
                        link_to('', @options[:cell_clicked_path] + '?' +  { start_time: I18n.l(@rows_hours[i] + (j - 2).days)}.to_query, style: 'display: block; width: 100%; height: 100%')
                      end
                    end
                  end

                  tds
                end
              end

              trs
            end

            content
          end

          # place the events at the end of the calendar
          # they will be placed at the right place on the calendar with some javascript magic
          @placed_events.each do |e|
            @event = e[1]
            @is_all_day = false
            tables << content_tag(:div, class: ['calendar_event', @event.status.underscore], data: { row: e[0][0], column: e[0][1], index: e[0][2] }, style: 'z-index: 1;') do
              content_tag(:div, class: 'content') { @view_context.capture(self, &block) }
            end
          end

          tables
        end
      end


      private

        def column(time_with_zone)
          ws = Date::DAYS_INTO_WEEK[@options[:week_start]]
          we = time_with_zone.strftime('%u').to_i - 1
          we += 7 if we <= ws
          (we - ws) % 7
        end

    end


    class MonthlyCalendarBuilder < AbstractCalendarBuilder

    def initialize(view_context, *args)

      opts = {
        id: "monthly_calendar_#{@@uuid}",
        week_start: :monday,
        week_end: :sunday,
        scope: 'monthly'
      }.merge!(args.extract_options!)

      opts[:week_start] = opts[:week_start].to_sym
      opts[:week_end]   = opts[:week_end].to_sym

      args << opts

      super(view_context, *args)

      # We calculate the number of days between :week_start and :week_end
      #ws = Date::DAYS_INTO_WEEK[@options[:week_start]]
      #we = Date::DAYS_INTO_WEEK[@options[:week_end]]
      #we += 7 if we <= ws

      @day_start = @day.beginning_of_month.to_date
      @day_end = @day.end_of_month.to_date

    end


    def compute

      super

      # We remove the events that doesn't fall in a weekday between :week_start and :week_end
      week_days = days_range
      @events.reject!{ |e| !week_days.include?(e.start_time.to_date.wday) }


      # We put the events in a [i, j] list where i == row, j == column, so:
      # i: {
      #   j: {
      #     event
      #   }
      # }

      @placed_events = { }

      @events.each do |e|
        i, j = day_to_row(e.start_time.to_date.day)

        @placed_events[i]    = { } unless @placed_events.has_key?(i)
        @placed_events[i][j] = [ ] unless @placed_events[i].has_key?(j)

        @placed_events[i][j] << e
      end

      self
    end


    def render(&block)
      content_tag(:div, class: 'monthly_calendar', id: @options[:id], style: 'position: relative;') do

        tables = ''.html_safe

        # controls
        tables << content_tag(:table, id: 'controls', class: 'styled', style: 'width: 100%;') do
          content_tag(:thead) do
            content_tag(:tr) do
              content = ''.html_safe
              content << content_tag(:th, style: 'width: 33%;') { link_to(@options[:verbose] ? I18n.t('calendarize.monthly_calendar.options.verbose', default: 'Compact') : I18n.t('calendarize.monthly_calendar.options.not_verbose', default: 'Full'), @options[:url] + '?' + to_query_params({ date: @day.to_date, verbose: !@options[:verbose] })) }
              content << content_tag(:th, style: 'width: 33%;') { (I18n.t('calendarize.monthly_calendar.month_of', default: 'Month of') + "<input type='text' class='datepicker' value='" + I18n.l(@day_start.to_date, format: @options[:date_format]) + "' />").html_safe }
              content << content_tag(:th, style: 'width: 33%;') do
                options = ''.html_safe
                options << link_to(I18n.t('calendarize.monthly_calendar.options.previous_month', default: 'Previous month'), @options[:url] + '?' +  to_query_params({ date: @day_start.prev_month.to_date }))
                options << ' | '
                options << link_to(I18n.t('calendarize.monthly_calendar.options.current_month', default: 'This month'), @options[:url] + '?' + to_query_params)
                options << ' | '
                options << link_to(I18n.t('calendarize.monthly_calendar.options.next_month', default: 'Next month'), @options[:url] + '?' + to_query_params({ date: @day_end.next_month.to_date }))
                options
              end
              content
            end
          end
        end

        # normal events
        tables << content_tag(:table, id: 'not_all_day', class: 'styled', style: 'width: 100%;') do
          content = ''.html_safe

          # The header that contains the weekday
          content << content_tag(:thead) do
            content_tag(:tr) do
              header = ''.html_safe

              days_range.each do |i|
                weekday = wday_to_string(i)

                header << content_tag(:th, style: "width: #{100/number_of_days_per_week}%") { I18n.t("calendarize.monthly_calendar.options.day.#{weekday}", default: weekday) }
              end

              header
            end
          end

          content << content_tag(:tbody) do

            trs = ''.html_safe

            rows_count.times do |i|
              # The cells header that contains the day of the month
              next unless @options[:verbose] || @placed_events.has_key?(i)

              trs << content_tag(:tr, class: 'row_days_of_month') do
                tds = ''.html_safe

                number_of_days_per_week.times do |j|
                  tds << content_tag(:td, class: ["row_#{i}", "column_#{j}"]) do
                    day = row_to_day(i, j)
                    day = day ? link_to(day.to_s, @options[:url] + '?' + to_query_params({ date: @day_start + (day - 1).days, scope: CalendarizeHelper::Scopes::DAILY })) : ''
                    day
                  end
                end

                tds
              end

              # The cell for the events
              trs << content_tag(:tr, class: 'row_events', data: { events_count: @placed_events.has_key?(i) ? @placed_events.max { |a, b| a.count <=> b.count }.count : 1 }) do
                tds = ''.html_safe

                number_of_days_per_week.times do |j|
                  tds << content_tag(:td, class: ["row_#{i}", "column_#{j}"]) do
                    day = row_to_day(i, j)

                    if @options[:cell_clicked_path].nil? || day.nil?

                    elsif @options[:cell_clicked_path].kind_of?(Array)
                      link_to('', @options[:cell_clicked_path][0] + '?' +  { start_time: I18n.l(@day_start + (day - 1).days)}.to_query, @options[:cell_clicked_path][1].merge({ style: 'display: block; width: 100%; height: 100%' }))
                    else
                      link_to('', @options[:cell_clicked_path] + '?' +  { start_time: I18n.l(@day_start + (day - 1).days)}.to_query, style: 'display: block; width: 100%; height: 100%')
                    end
                  end
                end

                tds
              end
            end

            trs
          end

          content
        end

        # place the events at the end of the calendar
        # they will be placed at the right place on the calendar with some javascript magic
        @placed_events.each do |row, columns|
          columns.each do |column, events|
            events.each_with_index do |event, i|
              @event = event
              @is_all_day = false

              tables << content_tag(:div, class: ['calendar_event', @event.status.underscore], data: { row: row, column: column, index: i }, style: 'z-index: 1;') do
                content_tag(:div, class: 'content') { @view_context.capture(self, &block) }
              end
            end
          end
        end

        tables
      end
    end


    private

      # We calculate the number of days between :week_start and :week_end
      def number_of_days_per_week
        ws = Date::DAYS_INTO_WEEK[@options[:week_start]]
        we = Date::DAYS_INTO_WEEK[@options[:week_end]]
        we += 7 if we <= ws
        we + 1
      end


      # Get the range of days to show
      def days_range
        ws = Date::DAYS_INTO_WEEK[@options[:week_start]]
        (ws...number_of_days_per_week).map{ |d| d % 7 }
      end


      # Transform a wday to string
      def wday_to_string(wday)
        Date::DAYNAMES[(wday + 1) % 7]
      end


      # Get the number of rows for the table
      def rows_count
        starting_wday = @day_start.wday - 1
        starting_wday = 6 if starting_wday < 0

        ((days_in_month(@day_start) + starting_wday) / 7.0).ceil
      end


      # Get the month's day corresponding to a row. Nil is returned if none.
      def row_to_day(i, j)
        starting_wday = @day_start.wday - 1
        starting_wday = 6 if starting_wday < 0

        base = (i * 7) + j

        return nil if base < starting_wday || base - starting_wday + 1 > days_in_month(@day_start)

        base - starting_wday + 1
      end


      # Get the row and column corresponding to a month's day.
      # Response format: [i, j]
      def day_to_row(month_day)
        starting_wday = @day_start.wday - 1
        starting_wday = 6 if starting_wday < 0

        base = month_day + starting_wday - 1

        #days_per_week = number_of_days_per_week

        [base / 7, base % 7]
      end


      # Number of days in the month of a given date
      def days_in_month(date)
        (Date.new(date.year, 12, 31) << (12 - date.month)).day
      end


      # Get the next weekday from today or a specified date
      # Example: date_of_next(:monday, Date.parse('2012-01-01')) => 2012-01-02
      def date_of_next(wday, from = nil)
        from ||= Date.today

        from_wday = (from.wday + 1) % 6
        to_wday = (Date::DAYS_INTO_WEEK[wday.to_sym] + 1) % 7

        delta_in_days = from_wday - to_wday
        delta_in_days += 7 if delta_in_days <= 0

        from + delta_in_days
      end

  end

end
