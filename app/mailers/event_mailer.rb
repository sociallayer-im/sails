class EventMailer < ApplicationMailer
  default from: 'Social Layer <send@app.sola.day>'

  def event_created()
    @recipient = params[:recipient]
    @event = Event.find(params[:event_id])
    subject = 'Social Layer Event'
    attachments['invite.ics'] = {:mime_type => 'text/calendar', :content => @event.to_cal}

    mail(to: [@recipient], subject: subject)
  end

  def event_updated()
    @recipient = params[:recipient]
    @event = Event.find(params[:event_id])
    subject = 'Social Layer Event Updated'
    attachments['invite.ics'] = {:mime_type => 'text/calendar', :content => @event.to_cal}

    mail(to: [@recipient], subject: subject)
  end

  def event_invited()
    @recipient = params[:recipient]
    @event = Event.find(params[:event_id])
    subject = 'Social Layer Event Invited'
    attachments['invite.ics'] = {:mime_type => 'text/calendar', :content => @event.to_cal}

    mail(to: [@recipient], subject: subject)
  end

end
