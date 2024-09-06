class SigninMailer < ApplicationMailer
  default from: 'Social Layer <send@app.sola.day>'
  def signin_email
    @code = params[:code]
    @recipient = params[:recipient]
    mail(to: [@recipient], subject: 'Social Layer SignIn')
  end
end
