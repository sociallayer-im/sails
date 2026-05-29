class GroupMailer < ApplicationMailer
  default from: 'Social Layer <send@app.sola.day>'
  def group_invite
    @group = params[:group]
    @recipient = params[:recipient]
    mail(to: [@recipient], subject: 'Social Layer Group Invite')
  end

  def member_broadcast
    @group = params[:group]
    @recipient = params[:recipient]
    @content = params[:content]
    mail(to: [@recipient], subject: params[:subject])
  end

  def ticket_purchased
    @group = params[:group]
    @ticket_item = params[:ticket_item]
    @recipient = params[:recipient]
    mail(to: [@recipient], subject: 'Social Layer New Ticket Purchase')
  end
end
