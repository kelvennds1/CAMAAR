# app/services/sigaa_importer.rb
class SigaaImporter
    class ImportResult
      attr_accessor :success, :errors, :created, :updated, :skipped
      
      def initialize
        @success = true
        @errors = []
        @created = { materias: 0, turmas: 0, docentes: 0, dicentes: 0, matriculas: 0 }
        @updated = { materias: 0, turmas: 0, docentes: 0, dicentes: 0, matriculas: 0 }
        @skipped = { materias: 0, turmas: 0, docentes: 0, dicentes: 0, matriculas: 0 }
      end
      
      def success?
        @success && @errors.empty?
      end
      
      def total_created
        @created.values.sum
      end
      
      def total_skipped
        @skipped.values.sum
      end
      
      def summary_message
        if success?
          "Importação concluída: #{total_created} novos registros criados, #{total_skipped} registros ignorados por já existirem"
        else
          "Erros na importação: #{@errors.join(', ')}"
        end
      end
    end
  
    def self.call(classes_file: nil, class_members_file: nil)
      new(classes_file, class_members_file).import
    end
  
    def initialize(classes_file, class_members_file)
      @classes_file = classes_file
      @class_members_file = class_members_file
      @result = ImportResult.new
    end
  
    def import
      validate_files
      return @result unless @result.success?
  
      ActiveRecord::Base.transaction do
        import_classes if @classes_file
        import_class_members if @class_members_file
      end
      
      @result
    rescue JSON::ParserError => e
      @result.success = false
      @result.errors << "Não foi possível processar o arquivo JSON: #{e.message}"
      @result
    rescue StandardError => e
      @result.success = false
      @result.errors << "Erro durante importação: #{e.message}"
      @result
    end
  
    private
  
    def validate_files
      if @classes_file.nil? && @class_members_file.nil?
        @result.success = false
        @result.errors << "Selecione ao menos um arquivo JSON para importação"
      end
    end
  
    def import_classes
      classes_data = parse_json_file(@classes_file)
      return unless classes_data
  
      classes_data.each do |class_data|
        import_materia_and_turma(class_data)
      end
    end
  
    def import_class_members
      members_data = parse_json_file(@class_members_file)
      return unless members_data
  
      members_data.each do |member_data|
        import_docente_dicentes_and_matriculas(member_data)
      end
    end
  
    def parse_json_file(file)
      content = file.respond_to?(:read) ? file.read : File.read(file)
      JSON.parse(content)
    rescue JSON::ParserError => e
      @result.success = false
      @result.errors << "Arquivo JSON inválido: #{e.message}"
      nil
    end
  
    def import_materia_and_turma(class_data)
      # Importar matéria
      materia = Materia.find_or_initialize_by(code: class_data['code'])
      
      if materia.new_record?
        materia.name = class_data['name']
        if materia.save
          @result.created[:materias] += 1
        else
          @result.errors << "Erro ao criar matéria #{class_data['code']}: #{materia.errors.full_messages.join(', ')}"
        end
      else
        @result.skipped[:materias] += 1
      end
  
      # Importar turma (se houver dados de turma)
      if class_data['class']
        import_turma(materia, class_data['class'])
      end
    end
  
    def import_turma(materia, class_info)
      # Precisamos encontrar o docente para criar a turma
      # Por enquanto, vamos criar turmas sem docente e atualizar depois
      turma = Turma.find_or_initialize_by(
        materia: materia,
        class_code: class_info['classCode'],
        semester: class_info['semester']
      )
  
      if turma.new_record?
        turma.time_slot = class_info['time']
        # Temporariamente, vamos buscar qualquer docente ou criar um placeholder
        turma.docente = find_or_create_placeholder_docente
        
        if turma.save
          @result.created[:turmas] += 1
        else
          @result.errors << "Erro ao criar turma: #{turma.errors.full_messages.join(', ')}"
        end
      else
        @result.skipped[:turmas] += 1
      end
    end
  
    def import_docente_dicentes_and_matriculas(member_data)
      materia = Materia.find_by(code: member_data['code'])
      unless materia
        @result.errors << "Matéria #{member_data['code']} não encontrada"
        return
      end
  
      turma = Turma.find_by(
        materia: materia,
        class_code: member_data['classCode'],
        semester: member_data['semester']
      )
      
      unless turma
        @result.errors << "Turma #{member_data['code']}-#{member_data['classCode']} não encontrada"
        return
      end
  
      # Importar docente
      if member_data['docente']
        docente = import_docente(member_data['docente'])
        if docente && turma.docente != docente
          turma.update(docente: docente)
          @result.updated[:turmas] += 1
        end
      end
  
      # Importar dicentes
      if member_data['dicente']
        member_data['dicente'].each do |dicente_data|
          import_dicente_and_matricula(dicente_data, turma)
        end
      end
    end
  
    def import_docente(docente_data)
      identifier = docente_data['usuario'] || docente_data['matricula']
      
      docente = Docente.find_or_initialize_by(identifier: identifier)
      
      if docente.new_record?
        docente.nome = docente_data['nome']
        docente.email = docente_data['email']
        docente.departamento = docente_data['departamento'] || 'Não informado'
        docente.titulacao = docente_data['formacao'] || 'Não informado'
        docente.ocupacao = docente_data['ocupacao'] || 'docente'
        
        if docente.save
          @result.created[:docentes] += 1
        else
          @result.errors << "Erro ao criar docente #{identifier}: #{docente.errors.full_messages.join(', ')}"
          return nil
        end
      else
        @result.skipped[:docentes] += 1
      end
      
      docente
    end
  
    def import_dicente_and_matricula(dicente_data, turma)
      identifier = dicente_data['usuario'] || dicente_data['matricula']
      
      dicente = Dicente.find_or_initialize_by(identifier: identifier)
      
      if dicente.new_record?
        dicente.nome = dicente_data['nome']
        dicente.email = dicente_data['email']
        dicente.matricula = dicente_data['matricula']
        dicente.curso = dicente_data['curso']
        dicente.ocupacao = dicente_data['ocupacao'] || 'dicente'
        dicente.formacao = dicente_data['formacao'] || 'graduando'
        
        if dicente.save
          @result.created[:dicentes] += 1
        else
          @result.errors << "Erro ao criar dicente #{identifier}: #{dicente.errors.full_messages.join(', ')}"
          return
        end
      else
        @result.skipped[:dicentes] += 1
      end
  
      # Criar matrícula
      matricula = Matricula.find_or_initialize_by(dicente: dicente, turma: turma)
      
      if matricula.new_record?
        matricula.status = 'ativo'
        matricula.enrollment_date = Date.current
        
        if matricula.save
          @result.created[:matriculas] += 1
        else
          @result.errors << "Erro ao criar matrícula: #{matricula.errors.full_messages.join(', ')}"
        end
      else
        @result.skipped[:matriculas] += 1
      end
    end
  
    def find_or_create_placeholder_docente
      Docente.find_or_create_by!(identifier: 'PLACEHOLDER_DOCENTE') do |d|
        d.nome = 'Docente Não Atribuído'
        d.email = 'placeholder@example.com'
        d.departamento = 'Não informado'
        d.titulacao = 'Não informado'
      end
    end
  end