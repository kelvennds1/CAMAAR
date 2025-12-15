# frozen_string_literal: true

namespace :sigaa do
  desc "Atualiza a base de dados com informações do SIGAA"
  task update_database: :environment do
    puts "Iniciando atualização da base de dados do SIGAA..."
    puts "Timestamp: #{Time.current}"

    # Caminhos dos arquivos JSON
    classes_file = Rails.root.join("classes.json")
    members_file = Rails.root.join("class_members.json")

    # Verificar se os arquivos existem
    unless File.exist?(classes_file) && File.exist?(members_file)
      puts "ERRO: Arquivos JSON não encontrados!"
      puts "Esperado: #{classes_file} e #{members_file}"
      exit 1
    end

    # Executar a importação/atualização
    begin
      result = SigaaImporter.call(
        classes_file: classes_file.to_s,
        class_members_file: members_file.to_s,
        operation_type: "Atualização"
      )

      if result.success?
        puts "\n✓ #{result.summary_message}"
        puts "\nDetalhamento:"
        puts "  Matérias - Criadas: #{result.created[:materias]}, Atualizadas: #{result.updated[:materias]}, Ignoradas: #{result.skipped[:materias]}"
        puts "  Turmas - Criadas: #{result.created[:turmas]}, Atualizadas: #{result.updated[:turmas]}, Ignoradas: #{result.skipped[:turmas]}"
        puts "  Docentes - Criados: #{result.created[:docentes]}, Atualizados: #{result.updated[:docentes]}, Ignorados: #{result.skipped[:docentes]}"
        puts "  Dicentes - Criados: #{result.created[:dicentes]}, Atualizados: #{result.updated[:dicentes]}, Ignorados: #{result.skipped[:dicentes]}"
        puts "  Matrículas - Criadas: #{result.created[:matriculas]}, Atualizadas: #{result.updated[:matriculas]}, Ignoradas: #{result.skipped[:matriculas]}"
        puts "\n✓ Atualização concluída com sucesso!"
      else
        puts "\n✗ Erro durante a atualização:"
        result.errors.each do |error|
          puts "  - #{error}"
        end
        exit 1
      end
    rescue StandardError => e
      puts "\n✗ Erro inesperado durante a atualização:"
      puts "  #{e.message}"
      puts "\nStacktrace:"
      puts e.backtrace.join("\n")
      exit 1
    end
  end

  desc "Exibe estatísticas da base de dados do SIGAA"
  task stats: :environment do
    puts "\n=== Estatísticas da Base de Dados ==="
    puts "Timestamp: #{Time.current}"
    puts "\nTotais:"
    puts "  Matérias: #{Materia.count}"
    puts "  Turmas: #{Turma.count}"
    puts "  Docentes: #{Docente.count}"
    puts "  Dicentes: #{Dicente.count}"
    puts "  Matrículas: #{Matricula.count}"

    puts "\nMatérias cadastradas:"
    Materia.all.each do |materia|
      puts "  - #{materia.code}: #{materia.name}"
    end

    puts "\nTurmas por semestre:"
    Turma.group(:semester).count.each do |semester, count|
      puts "  - #{semester}: #{count} turma(s)"
    end

    puts "\n==================================="
  end

  desc "Limpa dados placeholder da base de dados"
  task clean_placeholders: :environment do
    puts "Iniciando limpeza de dados placeholder..."

    placeholder_docente = Docente.find_by(identifier: "PLACEHOLDER_DOCENTE")

    if placeholder_docente
      # Verificar se há turmas usando o placeholder
      turmas_com_placeholder = Turma.where(docente: placeholder_docente).count

      if turmas_com_placeholder > 0
        puts "⚠ AVISO: Existem #{turmas_com_placeholder} turma(s) usando o docente placeholder."
        puts "  Execute a atualização completa antes de limpar os placeholders."
      else
        placeholder_docente.destroy
        puts "✓ Docente placeholder removido com sucesso."
      end
    else
      puts "✓ Nenhum docente placeholder encontrado."
    end
  end
end
