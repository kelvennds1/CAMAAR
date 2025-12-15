# Classe base abstrata para todos os modelos ActiveRecord da aplicação.
#
# Esta classe serve como classe pai para todos os modelos da aplicação CAMAAR,
# fornecendo configurações e comportamentos comuns.
#
# == Herança
# Todos os modelos da aplicação devem herdar desta classe em vez de
# herdar diretamente de ActiveRecord::Base.
#
# == Exemplo
#   class Usuario < ApplicationRecord
#     # ...
#   end
#
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
