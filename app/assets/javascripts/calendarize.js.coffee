class @DailyCalendar

  constructor: (id, opts) ->
    @inner = $('#' + id)
    @not_all_day = $('#not_all_day', @inner)
    @first_row = $('.row_content:first', @not_all_day)

    @options = {
      height: @first_row.outerHeight(true)
      width: 200
    }

    $.extend(@options, opts)

    this.init()


  init: =>
    $('.calendar_event', @inner).each (index, element) =>
      e = $(element)
      e.width(@options['width'])
      e.height(@options['height'] * (parseInt(e.data('row-end')) - parseInt(e.data('row-start'))) - 1)
      console.log $('#row_content_' + e.data('row-start'), @not_all_day)

      e.position({
        my: 'left top',
        at: 'left top',
        of: $('#row_content_' + e.data('row-start'), @not_all_day),
        offset: e.data('column') * (@options['width'] + 3) + ' 0',
        collision: 'none'
      })


class @WeeklyCalendar

  constructor: (id, opts) ->
    @inner = $('#' + id)

    @options = {
      height: 60
    }

    $.extend(@options, opts)

    this.init()


  init: =>
    $('.row_unit', @inner).each (index, element) =>
      e = $(element)
      e.height(e.data('events-count') * @options['height'])

    $('.calendar_event', @inner).each (index, element) =>
      e = $(element)

      # find the cell to put the event
      cell = $('.row_' + e.data('row') + '.column_' + e.data('column'), @inner)

      e.width(cell.outerWidth(true))
      e.height(@options['height'])

      e.position({
        my: 'left top',
        at: 'left top',
        of: $('.row_' + e.data('row') + '.column_' + e.data('column'), @inner),
        offset: '0 ' + e.data('index') * (@options['height']),
        collision: 'none'
      })


$(document).ready ->

  # Initialize every daily calendar on the page
  daily_calendars = []

  $('.daily_calendar').each (index, element) =>
    daily_calendars << new DailyCalendar(element.id)


  # Initialize every weekly calendar on the page
  weekly_calendars = []

  $('.weekly_calendar').each (index, element) =>
    weekly_calendars << new WeeklyCalendar(element.id)
