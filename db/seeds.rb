# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts 'Criando usuario administrador'

admin = Usuario.find_or_initialize_by(email: 'admin@caamar.com')

if admin.new_record?
    admin.assign_attributes(
      identifier: 'admin123',
      nome: 'Administrador',
      email: 'admin@camaar.com',
      type: 'Usuario',
      admin: true,
      password: 'senha123',
      password_confirmation: 'senha123'
    )
    
    if admin.save
      puts "   Administrador criado com sucesso!"
      puts "   Email: admin@camaar.com"
      puts "   Senha: senha123"
    else
      puts "   Erro ao criar administrador: #{admin.errors.full_messages.join(', ')}"
    end
  else
    puts "   Administrador já existe"
    puts "   Email: #{admin.email}"
  end
  
  puts "\n Total de usuários no sistema: #{Usuario.count}"
  puts "   Seeds concluídos!"