# Classe base para todos os jobs assíncronos da aplicação.
#
# Esta classe fornece configurações padrão para processamento
# de tarefas em background na aplicação CAMAAR usando ActiveJob.
#
# == Herança
# Todos os jobs da aplicação devem herdar desta classe.
#
# == Configurações disponíveis
# - retry_on: Configura retentativas automáticas para erros específicos
# - discard_on: Descarta jobs quando determinados erros ocorrem
#
# == Exemplo
#   class ProcessDataJob < ApplicationJob
#     queue_as :default
#
#     def perform(data)
#       # Processamento assíncrono
#     end
#   end
#
class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError
end
