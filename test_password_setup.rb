#!/usr/bin/env ruby
# Script para testar a funcionalidade de setup de senha
# Execute com: rails runner test_password_setup.rb

puts "\n=========================================="
puts "TESTANDO FLUXO DE SETUP DE SENHA"
puts "==========================================\n"

# 1. Criar um usuário com token de reset
puts "1. Criando usuário de teste..."
user = Dicente.create!(
  nome: "Usuário Teste",
  email: "teste@exemplo.com",
  identifier: "teste123",
  matricula: "123456",
  curso: "Ciência da Computação",
  pending_activation: true,
  password_reset_token: SecureRandom.urlsafe_base64(32),
  password_reset_sent_at: Time.current
)

puts "   ✓ Usuário criado: #{user.nome}"
puts "   ✓ Email: #{user.email}"
puts "   ✓ Pending activation: #{user.pending_activation}"
puts "   ✓ Token: #{user.password_reset_token[0..20]}..."

# 2. Gerar o link que seria enviado por email
token_param = user.signed_id(purpose: :password_reset, expires_in: 24.hours)
setup_url = "http://localhost:3000/password/setup?token=#{token_param}"

puts "\n2. Link de setup de senha gerado:"
puts "   #{setup_url}"

# 3. Verificar se o token não expirou
puts "\n3. Verificando validade do token..."
token_age = Time.current - user.password_reset_sent_at
puts "   ✓ Token criado há: #{token_age.to_i} segundos"
puts "   ✓ Token expira em: #{24.hours.to_i - token_age.to_i} segundos"
puts "   ✓ Token válido: #{token_age < 24.hours ? 'SIM' : 'NÃO'}"

puts "\n=========================================="
puts "COMO TESTAR:"
puts "==========================================\n"
puts "1. Inicie o servidor Rails:"
puts "   rails server"
puts ""
puts "2. Acesse o link no navegador:"
puts "   #{setup_url}"
puts ""
puts "3. Defina uma senha (mínimo 6 caracteres)"
puts ""
puts "4. Após definir a senha, você será redirecionado"
puts "   e poderá fazer login com:"
puts "   Email: #{user.email}"
puts "   Senha: (a que você definiu)"
puts ""
puts "=========================================="
puts "LIMPANDO..."
puts "==========================================\n"

# Limpar o usuário de teste
user.destroy
puts "✓ Usuário de teste removido\n"
