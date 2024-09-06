class EventMailer < ApplicationMailer
  default from: 'Social Layer <send@app.sola.day>'

  def new_event()
    @event = Event.find(params[:event_id])
    @recipient = params[:recipient]
    subject = 'Social Layer Event'

    attachments['invite.ics'] = {:mime_type => 'text/calendar', :content => @event.to_cal}

    mail(to: [@recipient], subject: subject)
  end

  def update_event
    ev = Event.find(params[:event_id])
    cal = Icalendar::Calendar.new
    cal.event do |e|
      e.dtstart     = Icalendar::Values::DateTime.new(ev.start_time.in_time_zone(ev.timezone))
      e.dtend       = Icalendar::Values::DateTime.new(ev.end_time.in_time_zone(ev.timezone))
      e.summary     = ev.title || ""
      e.description = ev.content || ""
      e.uid         = "sola-#{ev.id}"
      e.status      = "CONFIRMED"
      e.organizer   = Icalendar::Values::CalAddress.new("mailto:send@app.sola.day", cn: params[:group_name])
      e.attendee    = ["mailto:#{params[:recipient]}"]
      e.url         = "https://app.sola.day/event/detail/#{ev.id}"
      e.location    = "https://app.sola.day/event/detail/#{ev.id}"
    end

    ics = cal.to_ical
    attachments['invite.ics'] = {:mime_type => 'text/calendar', :content => ics}

    @recipient = params[:recipient]
    @email_title = params[:email_title]
    @event_title = params[:event_title]
    @event_group_url = params[:group_url]
    @event_group_name = params[:group_name]
    @event_timeinfo = params[:timeinfo]
    @event_location = params[:location]
    @event_location_url = params[:location_url]
    @event_url = params[:url]
    @event_object = ev
    mail(to: [@recipient], subject: params[:subject])
  end

  def event_invite
    ev = Event.find(params[:event_id])
    cal = Icalendar::Calendar.new
    cal.event do |e|
      e.dtstart     = Icalendar::Values::DateTime.new(ev.start_time)
      e.dtend       = Icalendar::Values::DateTime.new(ev.end_time)
      e.summary     = ev.title || ""
      e.description = ev.content || ""
      e.uid         = "sola-#{ev.id}"
      e.status      = "CONFIRMED"
      e.organizer   = Icalendar::Values::CalAddress.new("mailto:send@app.sola.day", cn: params[:group_name])
      e.attendee    = ["mailto:#{params[:recipient]}"]
      e.url         = "https://app.sola.day/event/detail/#{ev.id}"
      e.location    = "https://app.sola.day/event/detail/#{ev.id}"
    end

    ics = cal.to_ical
    attachments['invite.ics'] = {:mime_type => 'text/calendar', :content => ics}

    @recipient = params[:recipient]
    @event_title = params[:title]
    @event_group_url = params[:group_url]
    @event_group_name = params[:group_name]
    @event_timeinfo = params[:timeinfo]
    @event_location = params[:location]
    @event_location_url = params[:location_url]
    @event_url = params[:url]
    mail(to: [@recipient], subject: 'Social Layer Event Invite')
  end
end
