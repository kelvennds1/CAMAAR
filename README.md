# CAMAAR - Sistema de Avaliação de Turmas

Sistema de avaliação e gerenciamento de formulários para turmas acadêmicas.

## Sprint 1 - Resumo Executivo

### Papéis
- **Scrum Master**: Kelven Dias
- **Product Owner**: Equipe de Engenharia de Software

### Funcionalidades Desenvolvidas

| ID | Funcionalidade | Responsável | Pontos | Regras de Negócio |
|---|---|---|---|---|
| #99 | Responder formulário | Equipe | 5 | Participantes respondem questionários; todas as perguntas obrigatórias devem ser preenchidas; formulário bloqueado após submissão |
| #100 | Cadastrar usuários via SIGAA | Equipe | 3 | Importação de usuários do SIGAA; validação de duplicatas |
| #102 | Criar template de formulário | Equipe | 8 | Administradores criam templates com 3 tipos de questões (numérica 1-5, múltipla escolha, texto); mínimo 1 questão; múltipla escolha requer ≥2 opções |
| #103 | Criar formulário de avaliação | Equipe | 5 | Formulários baseados em templates; vinculados a turmas específicas |
| #105 | Configuração de senha | Equipe | 3 | Primeiro acesso requer definição de senha; validação de força da senha |
| #109 | Visualizar formulários pendentes | Equipe | 3 | Participantes veem formulários disponíveis para responder |
| #110 | Visualizar resultados | Equipe | 8 | Administradores acessam resultados consolidados; exportação de relatórios; gráficos e estatísticas |
| #111 | Visualizar templates | Equipe | 2 | Listagem de templates cadastrados |
| #112 | Editar e excluir templates | Equipe | 5 | Gerenciamento completo de templates; validação de templates em uso |
| #113 | Importar dados do SIGAA | Equipe | 8 | Importação de turmas, matérias e participantes via JSON; evita duplicação |

**Total de Pontos (Velocity)**: 50 pontos

### Política de Branching
- **Branch principal**: `master`
- **Branch de sprint**: `sprint-1`
- **Features**: Uma branch por funcionalidade (`sprint-1-bdd-<numero>`)
- **Convenção**: Pull Requests obrigatórios; CI deve passar antes do merge
- **Commits**: Mensagens descritivas no padrão `feat:`, `fix:`, `test:`, `chore:`

### Tecnologias
- **Ruby**: 3.4.1
- **Rails**: 8.1.1
- **BDD**: Cucumber + Capybara
- **CI/CD**: GitHub Actions

---

## Setup do Projeto

### Requisitos
* Ruby 3.4.1
* Rails 8.1.1
* SQLite3

### Instalação
```bash
bundle install
rails db:setup
```

### Executar testes BDD
```bash
bundle exec cucumber
```

### Rodar aplicação
```bash
bin/dev
```
