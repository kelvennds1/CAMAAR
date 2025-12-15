# Mailer responsável pelo envio de e-mails de configuração de senha.
#
# Este mailer envia instruções para que novos usuários possam
# configurar suas senhas no sistema CAMAAR.
#
# == Uso
#   PasswordSetupMailer.setup_instructions(user).deliver_later
#
# == E-mail remetente
# Configurado para 'noreply@camaar.unb.br'
#
class PasswordSetupMailer < ApplicationMailer
  default from: 'noreply@camaar.unb.br'

  # Envia e-mail com instruções para configuração de senha.
  #
  # == Parâmetros
  # * +user+ - Usuário que receberá as instruções (deve ter password_reset_token)
  #
  # == Variáveis de instância disponíveis na view
  # * +@user+ - O usuário destinatário
  # * +@setup_url+ - URL para configuração da senha
  #
  # == Retorno
  # Retorna um objeto Mail::Message pronto para envio.
  #
  def setup_instructions(user)
    @user = user
    @setup_url = password_setup_url(token: user.password_reset_token, host: default_url_options[:host])

    mail(
      to: @user.email,
      subject: 'Configure sua senha - Sistema CAMAAR'
    )
  end
end
