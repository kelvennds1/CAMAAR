# Como Testar a Feature 108 na Página Web

## 📋 Pré-requisitos

1. **Arquivos JSON no repositório**: Certifique-se de que os arquivos `classes.json` e `class_members.json` estão na raiz do projeto CAMAAR
2. **Servidor Rails rodando**: Execute `rails server` ou `bin/dev`
3. **Usuário Administrador**: Você precisa estar logado como administrador

## 🚀 Passos para Testar

### 1. Iniciar o Servidor

```bash
cd CAMAAR
bundle exec rails server
# ou
bin/dev
```

O servidor estará disponível em `http://localhost:3000` (ou a porta configurada)

### 2. Fazer Login como Administrador

1. Acesse `http://localhost:3000/login`
2. Faça login com um usuário administrador
3. Se não tiver um admin, crie um no console Rails:

```bash
rails console
```

```ruby
admin = Docente.create!(
  identifier: 'admin001',
  nome: 'Administrador',
  email: 'admin@unb.br',
  ocupacao: 'docente'
)
Usuario.create!(
  email: 'admin@unb.br',
  password: 'senha123',
  password_confirmation: 'senha123',
  usuario: admin,
  admin: true
)
```

### 3. Acessar a Página de Importação/Atualização

1. Navegue para: `http://localhost:3000/sigaa_imports`
2. Você verá:
   - Botão "Nova Importação" (azul) - para fazer upload de arquivos
   - Botão "🔄 Atualizar Base de Dados" (verde) - para atualização automática
   - Estatísticas da base de dados (contadores de matérias, turmas, docentes, etc.)

### 4. Testar a Atualização Automática

#### Cenário 1: Atualização com Dados Existentes

1. **Antes da atualização**, anote os números na página:
   - Quantidade de matérias
   - Quantidade de turmas
   - Quantidade de docentes
   - Quantidade de dicentes
   - Quantidade de matrículas

2. **Modifique os arquivos JSON** (opcional, para testar atualização):
   - Edite `classes.json` e mude o nome de uma matéria
   - Edite `class_members.json` e mude o email de um docente

3. **Clique no botão "🔄 Atualizar Base de Dados"**

4. **Confirme a ação** no diálogo de confirmação

5. **Verifique o resultado**:
   - Uma mensagem de sucesso deve aparecer no topo da página
   - A mensagem deve mostrar quantos registros foram criados, atualizados e ignorados
   - Os contadores na página devem refletir as mudanças

#### Cenário 2: Adicionar Novos Registros

1. **Adicione novos dados** nos arquivos JSON:
   - Adicione uma nova matéria em `classes.json`
   - Adicione um novo dicente em `class_members.json`

2. **Execute a atualização** clicando no botão verde

3. **Verifique**:
   - Os contadores devem aumentar
   - A mensagem deve indicar novos registros criados

#### Cenário 3: Testar com Arquivos Faltando

1. **Renomeie temporariamente** um dos arquivos JSON:
   ```bash
   mv classes.json classes.json.bak
   ```

2. **Tente executar a atualização**

3. **Verifique**:
   - Uma mensagem de erro deve aparecer
   - Informando que os arquivos não foram encontrados

4. **Restaure o arquivo**:
   ```bash
   mv classes.json.bak classes.json
   ```

## 🧪 Testes Automatizados (Cucumber)

Para testar via BDD, execute:

```bash
bundle exec cucumber features/108_update_sigaa_base.feature
```

## 📊 O que Observar

### Mensagens de Sucesso

A mensagem de sucesso deve ter o formato:
```
Atualização concluída: X novos registros criados, Y registros atualizados, Z registros ignorados
```

### Detalhamento Esperado

A mensagem detalha:
- **Matérias** - Criadas, Atualizadas, Ignoradas
- **Turmas** - Criadas, Atualizadas, Ignoradas
- **Docentes** - Criados, Atualizados, Ignorados
- **Dicentes** - Criados, Atualizados, Ignorados
- **Matrículas** - Criadas, Atualizadas, Ignoradas

### Comportamento Esperado

1. ✅ **Registros novos** → São criados
2. ✅ **Registros existentes com mudanças** → São atualizados
3. ✅ **Registros existentes sem mudanças** → São ignorados (não duplicados)
4. ✅ **Transações** → Se houver erro, nada é salvo (rollback)

## 🔍 Verificações Manuais

### 1. Verificar no Console Rails

```bash
rails console
```

```ruby
# Verificar matérias
Materia.all.each { |m| puts "#{m.code}: #{m.name}" }

# Verificar docentes
Docente.all.each { |d| puts "#{d.identifier}: #{d.nome} - #{d.email}" }

# Verificar dicentes
Dicente.count
Dicente.all.each { |d| puts "#{d.identifier}: #{d.nome}" }

# Verificar matrículas
Matricula.count
```

### 2. Verificar Logs

Os logs da atualização aparecem em:
- `log/development.log` (em desenvolvimento)
- Console do servidor Rails

Procure por:
```
Iniciando atualização da base de dados do SIGAA...
Timestamp: ...
✓ Atualização concluída: ...
```

## 🐛 Troubleshooting

### Problema: "Arquivos JSON não encontrados"

**Solução**: Certifique-se de que `classes.json` e `class_members.json` estão na raiz do projeto CAMAAR

```bash
ls -la CAMAAR/classes.json
ls -la CAMAAR/class_members.json
```

### Problema: "Acesso negado"

**Solução**: Certifique-se de estar logado como administrador

### Problema: Nada acontece ao clicar no botão

**Solução**: 
1. Verifique o console do navegador (F12) para erros JavaScript
2. Verifique os logs do servidor Rails
3. Verifique se a rota está correta: `POST /sigaa_imports/update_database`

## 📝 Checklist de Teste

- [ ] Servidor Rails está rodando
- [ ] Estou logado como administrador
- [ ] Arquivos JSON estão na raiz do projeto
- [ ] Consigo acessar `/sigaa_imports`
- [ ] Vejo o botão "🔄 Atualizar Base de Dados"
- [ ] Ao clicar, aparece confirmação
- [ ] Após confirmar, vejo mensagem de sucesso
- [ ] Os contadores na página são atualizados
- [ ] Registros existentes são atualizados corretamente
- [ ] Novos registros são adicionados
- [ ] Registros sem mudanças não são duplicados

## 🎯 Resultado Esperado

Após a atualização bem-sucedida, você deve ver:

1. ✅ Mensagem de sucesso no topo da página
2. ✅ Contadores atualizados na página
3. ✅ Dados no banco de dados refletindo as mudanças dos JSONs
4. ✅ Nenhum erro nos logs

## 🔗 URLs Relacionadas

- **Página de Importação/Atualização**: `http://localhost:3000/sigaa_imports`
- **Nova Importação**: `http://localhost:3000/sigaa_imports/new`
- **Login**: `http://localhost:3000/login`

## 💡 Dicas

1. **Teste incrementalmente**: Comece com pequenas mudanças nos JSONs
2. **Use o console Rails**: Para verificar os dados diretamente no banco
3. **Monitore os logs**: Acompanhe o que está acontecendo em tempo real
4. **Faça backup**: Antes de grandes atualizações, faça backup do banco de dados

## 📚 Documentação Relacionada

- [Feature 108 - Documentação Completa](./FEATURE_108_UPDATE_SIGAA.md)
- [Rake Tasks - Atualização via Linha de Comando](./FEATURE_108_UPDATE_SIGAA.md#rake-tasks)

