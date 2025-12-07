# language: pt
Funcionalidade: Atualização periódica da base de dados do SIGAA (#108)
  Como Administrador
  Quero atualizar periodicamente a base de dados com informações do SIGAA
  Para manter os dados sincronizados e atualizados

  Contexto:
    Dado que estou autenticado como administrador
    E existem dados já importados do SIGAA na base de dados

  Cenário: Atualizar dados modificados no SIGAA
    Dado que existem alterações nos dados do SIGAA
    E os arquivos JSON refletem essas alterações
    Quando eu executo a atualização da base de dados do SIGAA
    Então os registros existentes são atualizados com as novas informações
    E nenhum registro duplicado é criado
    E devo ver a mensagem de atualização que contém "Atualização concluída:"
    E devo ver a quantidade de registros atualizados

  Cenário: Adicionar novos registros durante atualização
    Dado que existem novos alunos matriculados nas turmas do SIGAA
    E os arquivos JSON contêm esses novos alunos
    Quando eu executo a atualização da base de dados do SIGAA
    Então os novos alunos são cadastrados no sistema
    E as matrículas correspondentes são criadas
    E os alunos existentes não são duplicados
    E devo ver a mensagem de atualização que contém "Atualização concluída:"

  Cenário: Atualizar informações de docentes
    Dado que um docente teve suas informações alteradas no SIGAA
    E o arquivo JSON reflete essas alterações
    Quando eu executo a atualização da base de dados do SIGAA
    Então as informações do docente são atualizadas no sistema
    E as turmas associadas mantêm a referência ao docente
    E devo ver a mensagem de atualização que contém "Atualização concluída:"

  Cenário: Atualizar informações de matérias
    Dado que uma matéria teve seu nome alterado no SIGAA
    E o arquivo JSON reflete essa alteração
    Quando eu executo a atualização da base de dados do SIGAA
    Então o nome da matéria é atualizado no sistema
    E todas as turmas associadas mantêm a referência correta
    E devo ver a mensagem de atualização que contém "Atualização concluída:"

  Cenário: Executar atualização automática via tarefa agendada
    Dado que existe uma tarefa agendada para atualização periódica
    E os arquivos JSON estão disponíveis no repositório
    Quando a tarefa agendada é executada
    Então a base de dados é atualizada automaticamente
    E um log da operação é gerado
    E o sistema continua funcionando normalmente

  Cenário: Tratar erros durante atualização
    Dado que ocorre um erro durante a atualização dos dados
    Quando eu executo a atualização da base de dados do SIGAA
    Então devo ver uma mensagem de erro descritiva
    E os dados já processados são mantidos consistentes
    E nenhum dado é corrompido no processo

