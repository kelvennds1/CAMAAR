# Execute com: rails runner create_test_user.rb

puts "\n🔧 Criando usuário de teste para senha..."

user = Dicente.create!(
  nome: "Teste Setup Senha",
  email: "teste.senha@aluno.unb.br",
  identifier: "testesenha",
  matricula: "999999",
  curso: "Teste",
  pending_activation: true,
  password_reset_token: "token-teste-123",
  password_reset_sent_at: Time.current
)

puts "✅ Usuário criado com sucesso!"
puts ""
puts "📧 Email: #{user.email}"
puts "🔑 Token: #{user.password_reset_token}"
puts ""
puts "🌐 URL para acessar:"
puts "   http://localhost:3000/password/setup?token=token-teste-123"
puts ""
puts "Após definir a senha, você pode fazer login com:"
puts "   Email: #{user.email}"
puts "   Senha: (a que você definir)"
puts ""
