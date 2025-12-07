# Feature 108 - Atualização Periódica da Base de Dados do SIGAA

## Descrição
Esta feature implementa a funcionalidade de atualização periódica da base de dados do CAMAAR com informações do SIGAA, permitindo sincronizar dados de matérias, turmas, docentes, discentes e matrículas.

## Arquivos Implementados

### 1. Feature BDD
**Arquivo:** `features/108_update_sigaa_base.feature`

Define os cenários de teste para atualização periódica:
- Atualizar dados modificados no SIGAA
- Adicionar novos registros durante atualização
- Atualizar informações de docentes
- Atualizar informações de matérias
- Executar atualização automática via tarefa agendada
- Tratar erros durante atualização

### 2. Step Definitions
**Arquivo:** `features/step_definitions/108_update_sigaa_base.rb`

Implementa os steps para todos os cenários de teste da feature, incluindo:
- Criação de dados de teste
- Simulação de alterações nos arquivos JSON
- Verificação de atualizações
- Validação de integridade dos dados

### 3. Serviço Aprimorado
**Arquivo:** `app/services/sigaa_importer.rb`

Melhorias implementadas:
- **Suporte a atualizações**: Detecta quando registros já existem e atualiza apenas os campos modificados
- **Rastreamento de operações**: Conta separadamente registros criados, atualizados e ignorados
- **Mensagens detalhadas**: Fornece relatório completo das operações realizadas
- **Validação de mudanças**: Só atualiza registros quando há mudanças reais

#### Principais Métodos Atualizados:
- `import_materia_and_turma`: Agora detecta e atualiza matérias existentes
- `import_turma`: Atualiza turmas quando horários mudam
- `import_docente`: Atualiza informações de docentes (email, departamento, etc.)
- `import_dicente_and_matricula`: Atualiza informações de discentes

#### Classe ImportResult Aprimorada:
```ruby
@created = { materias: 0, turmas: 0, docentes: 0, dicentes: 0, matriculas: 0 }
@updated = { materias: 0, turmas: 0, docentes: 0, dicentes: 0, matriculas: 0 }
@skipped = { materias: 0, turmas: 0, docentes: 0, dicentes: 0, matriculas: 0 }
```

### 4. Rake Tasks
**Arquivo:** `lib/tasks/sigaa.rake`

Três tarefas disponíveis:

#### a) `rake sigaa:update_database`
Atualiza a base de dados com os arquivos JSON do repositório.

**Uso:**
```bash
bundle exec rake sigaa:update_database
```

**Saída:**
```
Iniciando atualização da base de dados do SIGAA...
Timestamp: 2025-12-07 15:30:00 UTC

✓ Atualização concluída: 5 novos registros criados, 3 registros atualizados, 10 registros ignorados

Detalhamento:
  Matérias - Criadas: 1, Atualizadas: 1, Ignoradas: 1
  Turmas - Criadas: 1, Atualizadas: 1, Ignoradas: 1
  Docentes - Criados: 0, Atualizados: 1, Ignorados: 0
  Dicentes - Criados: 3, Atualizados: 0, Ignorados: 8
  Matrículas - Criadas: 0, Atualizadas: 0, Ignoradas: 0

✓ Atualização concluída com sucesso!
```

#### b) `rake sigaa:stats`
Exibe estatísticas da base de dados.

**Uso:**
```bash
bundle exec rake sigaa:stats
```

#### c) `rake sigaa:clean_placeholders`
Remove docentes placeholder da base de dados.

**Uso:**
```bash
bundle exec rake sigaa:clean_placeholders
```

### 5. Testes Unitários
**Arquivo:** `test/services/sigaa_importer_test.rb`

Testes implementados:
- Importação básica (mantidos do original)
- **Novos testes de atualização:**
  - `test "updates existing materia when name changes"`
  - `test "updates existing docente when information changes"`
  - `test "updates existing dicente when information changes"`
  - `test "tracks both created and updated counts"`
  - `test "skips records that have not changed"`

## Fluxo de Atualização

### 1. Detecção de Mudanças
O serviço compara cada campo do registro existente com os dados do JSON:

```ruby
if docente.nome != novo_nome
  docente.nome = novo_nome
  needs_update = true
end
```

### 2. Aplicação Seletiva
Apenas registros com mudanças são salvos:

```ruby
if needs_update
  if docente.save
    @result.updated[:docentes] += 1
  end
else
  @result.skipped[:docentes] += 1
end
```

### 3. Integridade Transacional
Todas as operações são executadas em uma transação:

```ruby
ActiveRecord::Base.transaction do
  import_classes if @classes_file
  import_class_members if @class_members_file
end
```

## Como Usar

### Atualização Manual
```bash
# Navegar até o diretório do projeto
cd CAMAAR

# Executar a rake task de atualização
bundle exec rake sigaa:update_database
```

### Atualização Automática (Agendada)
Você pode configurar um cronjob para executar a atualização periodicamente:

```bash
# Abrir o crontab
crontab -e

# Adicionar linha para executar diariamente às 3h da manhã
0 3 * * * cd /caminho/para/CAMAAR && bundle exec rake sigaa:update_database >> log/sigaa_update.log 2>&1
```

### Verificar Estatísticas
```bash
bundle exec rake sigaa:stats
```

## Executar Testes

### Testes Cucumber (BDD)
```bash
bundle exec cucumber features/108_update_sigaa_base.feature
```

### Testes Unitários
```bash
bundle exec rails test test/services/sigaa_importer_test.rb
```

## Estrutura dos Arquivos JSON

### classes.json
```json
[
  {
    "code": "CIC0097",
    "name": "BANCOS DE DADOS",
    "class": {
      "classCode": "TA",
      "semester": "2021.2",
      "time": "35T45"
    }
  }
]
```

### class_members.json
```json
[
  {
    "code": "CIC0097",
    "classCode": "TA",
    "semester": "2021.2",
    "dicente": [...],
    "docente": {
      "nome": "Nome do Docente",
      "departamento": "Departamento",
      "formacao": "DOUTORADO",
      "usuario": "12345678900",
      "email": "email@unb.br",
      "ocupacao": "docente"
    }
  }
]
```

## Tratamento de Erros

O serviço trata diversos tipos de erros:

1. **JSON Inválido**: Detecta e reporta problemas no formato JSON
2. **Matérias/Turmas Não Encontradas**: Valida existência antes de criar matrículas
3. **Erros de Validação**: Captura e reporta problemas do Active Record
4. **Rollback Automático**: Reverte todas as mudanças em caso de erro

## Benefícios da Implementação

1. ✅ **Sincronização Automática**: Mantém dados atualizados com o SIGAA
2. ✅ **Sem Duplicação**: Evita criação de registros duplicados
3. ✅ **Rastreamento Completo**: Sabe exatamente o que foi criado, atualizado ou ignorado
4. ✅ **Integridade de Dados**: Transações garantem consistência
5. ✅ **Relatórios Detalhados**: Fornece feedback completo das operações
6. ✅ **Testabilidade**: Cobertura completa com testes BDD e unitários
7. ✅ **Automação**: Pode ser agendado para execução periódica

## Próximos Passos (Opcional)

1. Configurar sistema de notificações para falhas na atualização
2. Implementar dashboard para visualizar histórico de atualizações
3. Adicionar logs mais detalhados com timestamps
4. Implementar dry-run para simular atualizações sem aplicá-las
5. Criar interface web para disparar atualizações manualmente

## Conclusão

A feature 108 foi implementada com sucesso, fornecendo uma solução robusta e testada para manter a base de dados do CAMAAR sincronizada com o SIGAA de forma automática e confiável.

