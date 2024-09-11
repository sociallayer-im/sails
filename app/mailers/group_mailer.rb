class GroupMailer < ApplicationMailer
  default from: 'Social Layer <send@app.sola.day>'
  def group_invite
    @group = params[:group]
    @recipient = params[:recipient]
    mail(to: [@recipient], subject: 'Social Layer Group Invite')
  end
end
