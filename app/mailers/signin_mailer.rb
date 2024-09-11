class SigninMailer < ApplicationMailer
  default from: 'Social Layer <send@app.sola.day>'
  def signin
    @code = params[:code]
    @recipient = params[:recipient]
    mail(to: [@recipient], subject: 'Social Layer Sign-In')
  end
end
