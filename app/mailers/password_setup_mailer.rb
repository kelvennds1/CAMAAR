# app/mailers/password_setup_mailer.rb
class PasswordSetupMailer < ApplicationMailer
  default from: 'noreply@camaar.unb.br'

  def setup_instructions(user)
    @user = user
    @setup_url = password_setup_url(token: user.password_reset_token, host: default_url_options[:host])

    mail(
      to: @user.email,
      subject: 'Configure sua senha - Sistema CAMAAR'
    )
  end
end
