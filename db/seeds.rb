
puts '=' * 60
puts 'INICIANDO SEEDS DO CAMAAR'
puts '=' * 60

# Limpar dados existentes (apenas em desenvolvimento)
if Rails.env.development?
  puts "\n  Limpando dados existentes..."
  Resposta.destroy_all
  Avaliacao.destroy_all
  Template.destroy_all
  Matricula.destroy_all
  Turma.destroy_all
  Materia.destroy_all
  Dicente.destroy_all
  # Não deletar administradores
  Docente.where(admin: false).destroy_all
  puts "   Dados limpos! (Administradores preservados)"
end

# ============================================================
# 1. CRIAR DOCENTES
# ============================================================
puts "\n Criando Docentes..."

docente1 = Docente.find_or_create_by!(email: 'maria.santos@unb.br') do |d|
  d.nome = "Profa. Maria Santos"
  d.identifier = "doc001"
  d.departamento = "Ciência da Computação"
  d.titulacao = "Doutora"
  d.password = "senha123"
end
puts "   #{docente1.nome} - #{docente1.email}"

docente2 = Docente.find_or_create_by!(email: 'joao.silva@unb.br') do |d|
  d.nome = "Prof. João Silva"
  d.identifier = "doc002"
  d.departamento = "Engenharia de Software"
  d.titulacao = "Doutor"
  d.password = "senha123"
end
puts "    #{docente2.nome} - #{docente2.email}"

# ============================================================
# 1.5. CRIAR ADMINISTRADOR
# ============================================================
puts "\n Criando Administrador..."

admin = Docente.find_or_create_by!(email: 'admin@camaar.com') do |d|
  d.nome = "Administrador do Sistema"
  d.identifier = "admin001"
  d.departamento = "Coordenação"
  d.titulacao = "Administrador"
  d.password = "senha123"
  d.admin = true
end
puts "   ✅ #{admin.nome} - #{admin.email}"

 # ============================================================
# 2. CRIAR MATÉRIAS
# ============================================================
puts "\n Criando Matérias..."

materia1 = Materia.find_or_create_by!(code: 'CIC0352') do |m|
  m.name = "Engenharia de Software"
end
puts "   #{materia1.code} - #{materia1.name}"

materia2 = Materia.find_or_create_by!(code: 'CIC0004') do |m|
  m.name = "Algoritmos e Programação de Computadores"
end
puts "   #{materia2.code} - #{materia2.name}"

materia3 = Materia.find_or_create_by!(code: 'CIC0097') do |m|
  m.name = "Banco de Dados"
end
puts "   #{materia3.code} - #{materia3.name}"

# ============================================================
# 3. CRIAR TURMAS DO SEMESTRE ATUAL
# ============================================================
puts "\n  Criando Turmas..."

current_semester = "#{Time.zone.today.year}.#{Time.zone.today.month <= 6 ? 1 : 2}"
puts "   Semestre atual: #{current_semester}"

turma1 = Turma.find_or_create_by!(
  materia: materia1, 
  class_code: "A", 
  semester: current_semester
) do |t|
  t.docente = docente1
  t.time_slot = "TER 14:00-16:00"
end
puts "    #{turma1.materia.name} - Turma #{turma1.class_code}"

turma2 = Turma.find_or_create_by!(
  materia: materia2, 
  class_code: "B", 
  semester: current_semester
) do |t|
  t.docente = docente2
  t.time_slot = "QUA 10:00-12:00"
end
puts "    #{turma2.materia.name} - Turma #{turma2.class_code}"

turma3 = Turma.find_or_create_by!(
  materia: materia3, 
  class_code: "C", 
  semester: current_semester
) do |t|
  t.docente = docente1
  t.time_slot = "QUI 16:00-18:00"
end
puts "    #{turma3.materia.name} - Turma #{turma3.class_code}"

# ============================================================
# 4. CRIAR DICENTES (ALUNOS)
# ============================================================
puts "\n Criando Dicentes..."

dicente1 = Dicente.find_or_create_by!(email: 'joao.aluno@aluno.unb.br') do |d|
  d.nome = "João Pedro Almeida"
  d.identifier = "aluno001"
  d.matricula = "190012345"
  d.curso = "Engenharia de Software"
  d.password = "senha123"
end
puts "    #{dicente1.nome} - Mat: #{dicente1.matricula}"

dicente2 = Dicente.find_or_create_by!(email: 'maria.aluna@aluno.unb.br') do |d|
  d.nome = "Maria Eduarda Silva"
  d.identifier = "aluno002"
  d.matricula = "190023456"
  d.curso = "Ciência da Computação"
  d.password = "senha123"
end
puts "    #{dicente2.nome} - Mat: #{dicente2.matricula}"

dicente3 = Dicente.find_or_create_by!(email: 'carlos.aluno@aluno.unb.br') do |d|
  d.nome = "Carlos Alberto Santos"
  d.identifier = "aluno003"
  d.matricula = "190034567"
  d.curso = "Engenharia de Software"
  d.password = "senha123"
end
puts "    #{dicente3.nome} - Mat: #{dicente3.matricula}"

# ============================================================
# 5. CRIAR MATRÍCULAS
# ============================================================
puts "\n Criando Matrículas..."

# João está matriculado em todas as 3 turmas
Matricula.find_or_create_by!(dicente: dicente1, turma: turma1) do |m|
  m.status = :ativo
end
puts "    #{dicente1.nome} → #{turma1.materia.name}"

Matricula.find_or_create_by!(dicente: dicente1, turma: turma2) do |m|
  m.status = :ativo
end
puts "    #{dicente1.nome} → #{turma2.materia.name}"

Matricula.find_or_create_by!(dicente: dicente1, turma: turma3) do |m|
  m.status = :ativo
end
puts "    #{dicente1.nome} → #{turma3.materia.name}"

# Maria está matriculada em 2 turmas
Matricula.find_or_create_by!(dicente: dicente2, turma: turma1) do |m|
  m.status = :ativo
end
puts "    #{dicente2.nome} → #{turma1.materia.name}"

Matricula.find_or_create_by!(dicente: dicente2, turma: turma2) do |m|
  m.status = :ativo
end
puts "    #{dicente2.nome} → #{turma2.materia.name}"

# Carlos está matriculado em 1 turma
Matricula.find_or_create_by!(dicente: dicente3, turma: turma3) do |m|
  m.status = :ativo
end
puts "    #{dicente3.nome} → #{turma3.materia.name}"

# ============================================================
# 6. CRIAR TEMPLATES COM QUESTÕES
# ============================================================
puts "\n Criando Templates..."

template1 = Template.find_or_initialize_by(
  name: "Avaliação Docente Padrão",
  docente: docente1
)

if template1.new_record?
  template1.description = "Template para avaliação de desempenho docente"
  template1.status = :published
  
  template1.template_questions.build([
    {
      prompt: "Como você avalia o domínio do conteúdo pelo professor?",
      question_type: "likert",
      position: 1,
      required: true,
      min_value: 1,
      max_value: 5
    },
    {
      prompt: "Como você avalia a clareza das explicações?",
      question_type: "likert",
      position: 2,
      required: true,
      min_value: 1,
      max_value: 5
    },
    {
      prompt: "O professor demonstrou disponibilidade para esclarecer dúvidas?",
      question_type: "likert",
      position: 3,
      required: true,
      min_value: 1,
      max_value: 5
    },
    {
      prompt: "Comentários adicionais (opcional)",
      question_type: "text",
      position: 4,
      required: false
    }
  ])
  
  template1.save!
  puts "    #{template1.name} (#{template1.template_questions.count} questões)"
else
  puts "     #{template1.name} já existe"
end

template2 = Template.find_or_initialize_by(
  name: "Avaliação de Infraestrutura",
  docente: docente2
)

if template2.new_record?
  template2.description = "Avaliação sobre recursos e infraestrutura"
  template2.status = :published
  
  template2.template_questions.build([
    {
      prompt: "Como você avalia os recursos didáticos utilizados?",
      question_type: "likert",
      position: 1,
      required: true,
      min_value: 1,
      max_value: 5
    },
    {
      prompt: "A infraestrutura da sala foi adequada?",
      question_type: "likert",
      position: 2,
      required: true,
      min_value: 1,
      max_value: 5
    }
  ])
  
  template2.save!
  puts "    #{template2.name} (#{template2.template_questions.count} questões)"
else
  puts "     #{template2.name} já existe"
end

# ============================================================
# 7. CRIAR AVALIAÇÕES COM DIFERENTES PRAZOS
# ============================================================
puts "\n Criando Avaliações..."

# Função helper para criar avaliação com questões
def criar_avaliacao_com_questoes(attrs, template)
  avaliacao = Avaliacao.find_or_initialize_by(
    title: attrs[:title],
    turma: attrs[:turma]
  )
  
  if avaliacao.new_record?
    avaliacao.assign_attributes(attrs)
    avaliacao.save!
    
    # Copiar questões do template
    template.template_questions.order(:position).each do |tq|
      avaliacao.questoes.create!(
        prompt: tq.prompt,
        question_type: tq.question_type,
        position: tq.position,
        mandatory: tq.required,
        min_value: tq.min_value,
        max_value: tq.max_value,
        options: tq.options,
        template_question: tq,
        weight: 1
      )
    end
    
    puts "    #{avaliacao.title} (prazo: #{avaliacao.due_date.strftime('%d/%m/%Y')})"
  else
    puts "     #{avaliacao.title} já existe"
  end
  
  avaliacao
end

# Avaliação URGENTE (vence em 2 dias) - Turma 1
avaliacao_urgente = criar_avaliacao_com_questoes({
  title: "Avaliação de Meio de Semestre - ES",
  turma: turma1,
  docente: docente1,
  template: template1,
  due_date: 2.days.from_now,
  max_score: 100,
  status: :published
}, template1)

# Avaliação NORMAL (vence em 15 dias) - Turma 1
avaliacao_normal = criar_avaliacao_com_questoes({
  title: "Avaliação Final - ES",
  turma: turma1,
  docente: docente1,
  template: template1,
  due_date: 15.days.from_now,
  max_score: 100,
  status: :published
}, template1)

# Avaliação VENCIDA (prazo passou há 5 dias) - Turma 2
avaliacao_vencida = criar_avaliacao_com_questoes({
  title: "Avaliação de Início de Semestre - APC",
  turma: turma2,
  docente: docente2,
  template: template2,
  due_date: 5.days.ago,
  max_score: 100,
  status: :published
}, template2)

# Avaliação RESPONDIDA (para testar que não aparece) - Turma 3
avaliacao_respondida = criar_avaliacao_com_questoes({
  title: "Avaliação Já Respondida - BD",
  turma: turma3,
  docente: docente1,
  template: template1,
  due_date: 10.days.from_now,
  max_score: 100,
  status: :published
}, template1)

# ============================================================
# 8. CRIAR UMA RESPOSTA (para testar filtro)
# ============================================================
puts "\n  Criando Resposta de Exemplo..."

resposta = Resposta.find_or_create_by!(
  avaliacao: avaliacao_respondida,
  dicente: dicente1
) do |r|
  r.status = :submitted
  r.submitted_at = Time.current
end
puts "    #{dicente1.nome} respondeu: #{avaliacao_respondida.title}"

# ============================================================
# RESUMO FINAL
# ============================================================
puts "\n" + "=" * 60
puts " SEEDS CONCLUÍDOS COM SUCESSO!"
puts "=" * 60

puts "\n RESUMO:"
puts "   • Docentes: #{Docente.count}"
puts "   • Dicentes: #{Dicente.count}"
puts "   • Matérias: #{Materia.count}"
puts "   • Turmas: #{Turma.count}"
puts "   • Matrículas: #{Matricula.count}"
puts "   • Templates: #{Template.count}"
puts "   • Avaliações: #{Avaliacao.count}"
puts "   • Respostas: #{Resposta.count}"

puts "\n CREDENCIAIS PARA TESTE:"
puts "\n  ADMINISTRADOR:"
puts "     Email: admin@camaar.com"
puts "     Senha: senha123"

puts "\n   ALUNO (Dicente) - Tem formulários pendentes:"
puts "     Email: joao.aluno@aluno.unb.br"
puts "     Senha: senha123"

puts "\n   ALUNA (Dicente) - Também tem formulários:"
puts "     Email: maria.aluna@aluno.unb.br"
puts "     Senha: senha123"

puts "\n   PROFESSORA (Docente):"
puts "     Email: maria.santos@unb.br"
puts "     Senha: senha123"

puts "\n FORMULÁRIOS PENDENTES PARA JOÃO:"
avaliacoes_pendentes = Avaliacao.pending_for_dicente(dicente1)
puts "   Total: #{avaliacoes_pendentes.count}"
avaliacoes_pendentes.each do |aval|
  days_until = (aval.due_date.to_date - Date.today).to_i
  status = if days_until < 0
    " VENCIDO (#{days_until.abs} dias atrás)"
  elsif days_until <= 3
    " URGENTE (#{days_until} dias)"
  else
    " NORMAL (#{days_until} dias)"
  end
  puts "   • #{aval.title} - #{status}"
end