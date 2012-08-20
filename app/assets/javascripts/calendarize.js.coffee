class @DailyCalendar

  constructor: (id, opts) ->
    @inner = $('#' + id)
    @not_all_day = $('#not_all_day', @inner)
    @not_all_day_events = $('.not_all_day_events', @inner)
    @first_row = $('.row_content:first', @not_all_day)

    @options = {
      height: @first_row.outerHeight(true)
      width: 200
    }

    $.extend(@options, opts)

    this.init()


  init: =>
    # initialize events
    @not_all_day_events.css('position', 'absolute')
    @not_all_day_events.css('overflow-x', 'hidden')
    @not_all_day_events.width(@not_all_day.width() - @first_row.position().left) unless @first_row.empty?
    @not_all_day_events.height(@not_all_day.height() - @not_all_day.position().top)

    @not_all_day_events.position({
      my: 'left top',
      at: 'left top',
      of: @first_row,
      collision: 'none'
    }) unless @first_row.empty?

    $('.calendar_event', @inner).each (index, element) =>
      e = $(element)

      row_start = parseInt(e.data('row-start'))
      row_end = parseInt(e.data('row-end'))

      e.width(@options['width'])
      e.height(@options['height'] * (row_end - row_start) - 1)
      e.css('position', 'absolute')

      e.position({
        my: 'left top',
        at: 'left top',
        of: @not_all_day_events,
        offset: e.data('column') * (@options['width'] + 3) + ' ' + ($('#row_content_' + row_start, @not_all_day).position().top - @first_row.position().top),
        collision: 'none'
      })


    # Set height of rows
    $('td', @inner).each (index, element) =>
      e = $(element)
      e.css('height', e.height())

    # initialize date picker
    $('.datepicker', @inner).datepicker(
      dateFormat: 'yy-mm-dd',
      onSelect: (date, instance) ->

        if window.location.href.search('calendar%5Bdate%5D') == -1
          window.location.href = window.location.href + '?calendar%5Bdate%5D=' + date
        else
          window.location.href = window.location.href
            .replace(/calendar_date=[0-9\-]*/, 'calendar_date=' + date)
            .replace(/calendar%5Bdate%5D=[0-9\-]*/, 'calendar%5Bdate%5D=' + date)
    )


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
      e.css('position', 'absolute')

      e.position({
        my: 'left top',
        at: 'left top',
        of: $('.row_' + e.data('row') + '.column_' + e.data('column'), @inner),
        offset: '0 ' + e.data('index') * (@options['height']),
        collision: 'none'
      })


    # Set height of rows
    $('td', @inner).each (index, element) =>
      e = $(element)
      e.css('height', e.height())


    # initialize date picker
    $('.datepicker', @inner).datepicker(
      dateFormat: 'yy-mm-dd',
      onSelect: (date, instance) ->

        if window.location.href.search('calendar%5Bdate%5D') == -1
          window.location.href = window.location.href + '?calendar%5Bdate%5D=' + date
        else
          window.location.href = window.location.href
            .replace(/calendar_date=[0-9\-]*/, 'calendar_date=' + date)
            .replace(/calendar%5Bdate%5D=[0-9\-]*/, 'calendar%5Bdate%5D=' + date)
    )


class @MonthlyCalendar

  constructor: (id, opts) ->
    @inner = $('#' + id)

    @options = {
      height: 70
    }

    $.extend(@options, opts)

    this.init()


  init: =>
    $('.row_events', @inner).each (index, element) =>
      e = $(element)
      e.height(e.data('events-count') * @options['height'])

    $('.calendar_event', @inner).each (index, element) =>
      e = $(element)

      # find the cell to put the event
      cell = $('.row_events >' + '.row_' + e.data('row') + '.column_' + e.data('column'), @inner)

      e.width(cell.outerWidth(true) - 1)
      e.height(@options['height'])
      e.css('position', 'absolute')

      e.position({
        my: 'left top',
        at: 'left top',
        of: $('.row_events >' + '.row_' + e.data('row') + '.column_' + e.data('column'), @inner),
        offset: '0 ' + e.data('index') * (@options['height']),
        collision: 'none'
      })


    # Set height of rows
    $('td', @inner).each (index, element) =>
      e = $(element)
      e.css('height', e.height())


    # initialize date picker
    $('.datepicker', @inner).datepicker(
      dateFormat: 'mm-yy'
      changeMonth: true
      changeYear: true
      showButtonPanel: true
      onClose: (date, instance) ->
        month = $('#ui-datepicker-div .ui-datepicker-month :selected', @inner).val()
        year = $('#ui-datepicker-div .ui-datepicker-year :selected', @inner).val()

        before = $(this).val()
        $(this).val($.datepicker.formatDate('yy-mm', new Date(year, month, 1)))
        now = $(this).val()

        return if now == before

        date = now + '-1'

        if window.location.href.search('calendar%5Bdate%5D') == -1
          window.location.href = window.location.href + '?calendar%5Bdate%5D=' + date
        else
          window.location.href = window.location.href
            .replace(/calendar_date=[0-9\-]*/, 'calendar_date=' + date)
            .replace(/calendar%5Bdate%5D=[0-9\-]*/, 'calendar%5Bdate%5D=' + date)
    )

    $('.datepicker', @inner).bind 'focus', ->
      $('.ui-datepicker-calendar', @inner).hide()
      $('#ui-datepicker-div', @inner).position(
        my: 'center top'
        at: 'center bottom'
        of: $(this)
      )


$(document).ready ->

  # Initialize every daily calendar on the page
  daily_calendars = []

  $('.daily_calendar').each (index, element) =>
    daily_calendars << new DailyCalendar(element.id)


  # Initialize every weekly calendar on the page
  weekly_calendars = []

  $('.weekly_calendar').each (index, element) =>
    weekly_calendars << new WeeklyCalendar(element.id)


  # Initialize every monthly calendar on the page
  monthly_calendars = []

  $('.monthly_calendar').each (index, element) =>
    monthly_calendars << new MonthlyCalendar(element.id)
