# language: pt

Funcionalidade: Criar template de formulário (#102)
  Como Administrador
  Quero criar um template contendo perguntas padronizadas
  Para reutilizar as avaliações das turmas

  Contexto:
    Dado que existe um docente chamado "Prof. Ana Costa"
    E acesso a página de templates

  @happy
  Cenário: Criar template com questões dos três tipos
    Quando preencho o nome do template com "Template Avaliação 2025.1"
    E seleciono o docente "Prof. Ana Costa"
    E adiciono a questão 1 do tipo "Escala 1-5" com o texto "Satisfação geral"
    E adiciono a questão 2 do tipo "Múltipla escolha" com o texto "Infraestrutura" e as opções:
      | Muito bom |
      | Bom       |
      | Regular   |
      | Ruim      |
    E adiciono a questão 3 do tipo "Texto" com o texto "Sugestões"
    E clico em "Criar template"
    Então devo ver a mensagem "Template criado com sucesso."
    E devo ver o card do template "Template Avaliação 2025.1" na listagem

  @happy
  Cenário: Manter a ordem das questões após salvar
    Quando preencho o nome do template com "Template Ordenado"
    E seleciono o docente "Prof. Ana Costa"
    E adiciono a questão 1 do tipo "Escala 1-5" com o texto "Q1"
    E adiciono a questão 2 do tipo "Múltipla escolha" com o texto "Q2" e as opções:
      | Opção A |
      | Opção B |
    E adiciono a questão 3 do tipo "Texto" com o texto "Q3"
    E clico em "Criar template"
    Então ao visualizar o template "Template Ordenado" devo ver as perguntas na ordem:
      | Q1 |
      | Q2 |
      | Q3 |

  @sad
  Cenário: Tentar criar template sem nome
    Quando seleciono o docente "Prof. Ana Costa"
    E adiciono a questão 1 do tipo "Texto" com o texto "Comentário"
    E clico em "Criar template"
    Então devo ver a mensagem "Informe o nome do template"
    E o template "Comentário" não é criado

  @sad
  Cenário: Múltipla escolha sem opções
    Quando preencho o nome do template com "Template Sem Opções"
    E seleciono o docente "Prof. Ana Costa"
    E adiciono a questão 1 do tipo "Múltipla escolha" com o texto "Escolha" e nenhuma opção
    E clico em "Criar template"
    Então devo ver a mensagem "Adicione pelo menos duas opções"
    E o template "Template Sem Opções" não é criado

  @sad
  Cenário: Template sem nenhuma questão
    Quando preencho o nome do template com "Template Vazio"
    E seleciono o docente "Prof. Ana Costa"
    E removo todas as questões
    E clico em "Criar template"
    Então devo ver a mensagem "Adicione pelo menos uma questão"
    E o template "Template Vazio" não é criado

  @sad
  Cenário: Nome duplicado para o mesmo docente
    Dado que já existe um template chamado "Template Avaliação 2025.1" para o docente "Prof. Ana Costa"
    Quando preencho o nome do template com "Template Avaliação 2025.1"
    E seleciono o docente "Prof. Ana Costa"
    E adiciono a questão 1 do tipo "Texto" com o texto "Q1"
    E clico em "Criar template"
    Então devo ver a mensagem "Já existe um template com esse nome para o docente selecionado"
    E o template "Template Avaliação 2025.1" não é criado

  @sad
  Cenário: Questão numérica fora da escala 1-5
    Quando preencho o nome do template com "Template Numérico Inválido"
    E seleciono o docente "Prof. Ana Costa"
    E adiciono a questão 1 do tipo "Escala 1-5" com o texto "Nota" e escala inválida
    E clico em "Criar template"
    Então devo ver a mensagem "A escala numérica deve ser de 1 a 5"
    E o template "Template Numérico Inválido" não é criado
