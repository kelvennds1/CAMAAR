# Classe base para todos os mailers da aplicação.
#
# Esta classe fornece configurações padrão para o envio de e-mails
# na aplicação CAMAAR.
#
# == Configurações
# - from: Endereço de e-mail remetente padrão
# - layout: Template de layout para e-mails
#
# == Herança
# Todos os mailers da aplicação devem herdar desta classe.
#
# == Exemplo
#   class NotificationMailer < ApplicationMailer
#     def notify(user)
#       mail(to: user.email, subject: 'Notificação')
#     end
#   end
#
class ApplicationMailer < ActionMailer::Base
  default from: "from@example.com"
  layout "mailer"
end
