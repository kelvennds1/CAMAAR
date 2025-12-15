# app/services/sigaa_importer.rb
##
# Service responsible for importing data from SIGAA JSON files into the system.
# Handles creation and update of subjects (matérias), classes (turmas), teachers (docentes),
# students (dicentes), and enrollments (matrículas).
#
# Example:
#   result = SigaaImporter.call(
#     classes_file: File.open('turmas.json'),
#     class_members_file: File.open('turma_docente_dicentes.json')
#   )
#   puts result.summary_message
#
class SigaaImporter
  ##
  # Result object that tracks the import operation statistics and errors.
  #
  class ImportResult
    attr_accessor :success, :errors, :created, :updated, :skipped, :operation_type

    ##
    # Initializes a new import result tracker.
    #
    # ==== Parameters
    # * +operation_type+ - String describing the type of operation (default: 'Importação')
    #
    def initialize(operation_type: 'Importação')
      @success = true
      @errors = []
      @created = { materias: 0, turmas: 0, docentes: 0, dicentes: 0, matriculas: 0 }
      @updated = { materias: 0, turmas: 0, docentes: 0, dicentes: 0, matriculas: 0 }
      @skipped = { materias: 0, turmas: 0, docentes: 0, dicentes: 0, matriculas: 0 }
      @operation_type = operation_type
    end

    ##
    # Checks if the import was successful.
    #
    # ==== Returns
    # * Boolean - true if successful and no errors occurred
    #
    def success?
      @success && @errors.empty?
    end

    ##
    # Returns the total number of created records across all types.
    #
    # ==== Returns
    # * Integer - sum of all created records
    #
    def total_created
      @created.values.sum
    end

    ##
    # Returns the total number of updated records across all types.
    #
    # ==== Returns
    # * Integer - sum of all updated records
    #
    def total_updated
      @updated.values.sum
    end

    ##
    # Returns the total number of skipped records across all types.
    #
    # ==== Returns
    # * Integer - sum of all skipped records
    #
    def total_skipped
      @skipped.values.sum
    end

    ##
    # Generates a human-readable summary message of the import operation.
    #
    # ==== Returns
    # * String - summary message with operation results or errors
    #
    def summary_message
      success? ? success_summary : error_summary
    end

    private

    def success_summary
      parts = build_summary_parts
      parts.any? ? "#{@operation_type} concluída: #{parts.join(', ')}" : no_changes_message
    end

    def build_summary_parts
      [].tap do |parts|
        parts << "#{total_created} novos registros criados" if total_created.positive?
        parts << "#{total_updated} registros atualizados" if total_updated.positive?
        parts << "#{total_skipped} registros ignorados por já existirem" if total_skipped.positive?
      end
    end

    def no_changes_message
      "#{@operation_type} concluída: nenhuma alteração necessária"
    end

    def error_summary
      "Erros na #{@operation_type.downcase}: #{@errors.join(', ')}"
    end
  end

  ##
  # Class method to perform SIGAA data import.
  #
  # ==== Parameters
  # * +classes_file+ - File object containing JSON data for classes (turmas)
  # * +class_members_file+ - File object containing JSON data for class members (docentes and dicentes)
  # * +operation_type+ - String describing the operation type (default: 'Importação')
  #
  # ==== Returns
  # * ImportResult object with operation statistics and errors
  #
  # ==== Side Effects
  # * Creates/updates records in the database (Materia, Turma, Docente, Dicente, Matricula)
  # * Sends password setup emails to newly created users
  #
  def self.call(classes_file: nil, class_members_file: nil, operation_type: 'Importação')
    new(classes_file, class_members_file, operation_type).import
  end

  ##
  # Initializes a new SigaaImporter instance.
  #
  # ==== Parameters
  # * +classes_file+ - File object with classes JSON data
  # * +class_members_file+ - File object with class members JSON data
  # * +operation_type+ - String describing the operation (default: 'Importação')
  #
  def initialize(classes_file, class_members_file, operation_type = 'Importação')
    @classes_file = classes_file
    @class_members_file = class_members_file
    @result = ImportResult.new(operation_type: operation_type)
  end

  ##
  # Performs the import operation by reading JSON files and creating/updating database records.
  #
  # ==== Returns
  # * ImportResult object with statistics and any errors
  #
  # ==== Side Effects
  # * Validates input files
  # * Imports classes (turmas) and their subjects (matérias)
  # * Imports class members (teachers and students) and enrollments
  #
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
    materia = find_or_create_materia(class_data)
    import_turma(materia, class_data['class']) if class_data['class']
  end

  def find_or_create_materia(class_data)
    materia = Materia.find_or_initialize_by(code: class_data['code'])

    if materia.new_record?
      create_materia(materia, class_data)
    else
      update_materia_if_needed(materia, class_data)
    end

    materia
  end

  def create_materia(materia, class_data)
    materia.name = class_data['name']
    if materia.save
      @result.created[:materias] += 1
    else
      @result.errors << "Erro ao criar matéria #{class_data['code']}: #{materia.errors.full_messages.join(', ')}"
    end
  end

  def update_materia_if_needed(materia, class_data)
    return @result.skipped[:materias] += 1 if materia.name == class_data['name']

    materia.name = class_data['name']
    if materia.save
      @result.updated[:materias] += 1
    else
      @result.errors << "Erro ao atualizar matéria #{class_data['code']}: #{materia.errors.full_messages.join(', ')}"
    end
  end

  def import_turma(materia, class_info)
    turma = find_or_initialize_turma(materia, class_info)

    if turma.new_record?
      create_new_turma(turma, class_info)
    else
      update_turma_if_needed(turma, class_info)
    end
  end

  def find_or_initialize_turma(materia, class_info)
    Turma.find_or_initialize_by(
      materia: materia,
      class_code: class_info['classCode'],
      semester: class_info['semester']
    )
  end

  def create_new_turma(turma, class_info)
    turma.time_slot = class_info['time']
    turma.docente = find_or_create_placeholder_docente

    if turma.save
      @result.created[:turmas] += 1
    else
      @result.errors << "Erro ao criar turma: #{turma.errors.full_messages.join(', ')}"
    end
  end

  def update_turma_if_needed(turma, class_info)
    return @result.skipped[:turmas] += 1 if turma.time_slot == class_info['time']

    turma.time_slot = class_info['time']
    if turma.save
      @result.updated[:turmas] += 1
    else
      @result.errors << "Erro ao atualizar turma: #{turma.errors.full_messages.join(', ')}"
    end
  end

  ##
  # Imports docente, dicentes, and their matriculas for a given class.
  #
  # ==== Parameters
  # * +member_data+ - Hash containing code, classCode, semester, docente, dicente arrays
  #
  # ==== Side Effects
  # * Creates/updates Docente, Dicente, and Matricula records
  # * Updates @result counters
  #
  def import_docente_dicentes_and_matriculas(member_data)
    turma = find_turma_for_member_data(member_data)
    return unless turma

    import_docente_for_turma(member_data, turma)
    import_dicentes_for_turma(member_data, turma)
  end

  ##
  # Finds the turma for the given member data.
  #
  def find_turma_for_member_data(member_data)
    materia = Materia.find_by(code: member_data['code'])
    unless materia
      @result.errors << "Matéria #{member_data['code']} não encontrada"
      return nil
    end

    turma = Turma.find_by(
      materia: materia,
      class_code: member_data['classCode'],
      semester: member_data['semester']
    )

    unless turma
      @result.errors << "Turma #{member_data['code']}-#{member_data['classCode']} não encontrada"
      return nil
    end

    turma
  end

  ##
  # Imports/updates docente for a turma if present in member_data.
  #
  def import_docente_for_turma(member_data, turma)
    return unless member_data['docente']

    docente = import_docente(member_data['docente'])
    update_turma_docente(turma, docente) if docente
  end

  ##
  # Updates turma docente if different from current.
  #
  def update_turma_docente(turma, docente)
    return if turma.docente == docente

    turma.update(docente: docente)
    @result.updated[:turmas] += 1
  end

  ##
  # Imports dicentes and their matriculas for a turma.
  #
  def import_dicentes_for_turma(member_data, turma)
    return unless member_data['dicente']

    member_data['dicente'].each do |dicente_data|
      import_dicente_and_matricula(dicente_data, turma)
    end
  end

  ##
  # Imports or updates a teacher (docente) from SIGAA data.
  #
  # ==== Parameters
  # * +docente_data+ - Hash containing teacher information (nome, email, departamento, formacao, ocupacao)
  #
  # ==== Returns
  # * Docente object (created or updated)
  #
  # ==== Side Effects
  # * Creates or updates Docente record in database
  # * Sends password setup email to newly created teachers
  # * Updates import result counters
  #
  def import_docente(docente_data)
    identifier = docente_data['usuario'] || docente_data['matricula']
    docente = Docente.find_or_initialize_by(identifier: identifier)

    if docente.new_record?
      create_new_docente(docente, docente_data, identifier)
    else
      update_existing_docente(docente, docente_data, identifier)
    end

    docente
  end

  def create_new_docente(docente, docente_data, identifier)
    assign_docente_attributes(docente, docente_data)
    setup_docente_activation(docente)

    if docente.save
      @result.created[:docentes] += 1
      send_password_setup_email(docente)
    else
      @result.errors << "Erro ao criar docente #{identifier}: #{docente.errors.full_messages.join(', ')}"
    end
  end

  def assign_docente_attributes(docente, docente_data)
    docente.nome = docente_data['nome']
    docente.email = docente_data['email']
    docente.departamento = docente_data['departamento'] || 'Não informado'
    docente.titulacao = docente_data['formacao'] || 'Não informado'
    docente.ocupacao = docente_data['ocupacao'] || 'docente'
  end

  def setup_docente_activation(docente)
    docente.pending_activation = true if docente.respond_to?(:pending_activation)
    docente.password_reset_token = SecureRandom.urlsafe_base64(32)
    docente.password_reset_sent_at = Time.current
  end

  def update_existing_docente(docente, docente_data, identifier)
    return unless docente_needs_update?(docente, docente_data)

    assign_docente_attributes(docente, docente_data)

    if docente.save
      @result.updated[:docentes] += 1
    else
      @result.errors << "Erro ao atualizar docente #{identifier}: #{docente.errors.full_messages.join(', ')}"
    end
  end

  def docente_needs_update?(docente, docente_data)
    attributes_to_check = {
      nome: docente_data['nome'],
      email: docente_data['email'],
      departamento: docente_data['departamento'] || 'Não informado',
      titulacao: docente_data['formacao'] || 'Não informado',
      ocupacao: docente_data['ocupacao'] || 'docente'
    }

    changed = attributes_to_check.any? { |attr, new_value| docente.send(attr) != new_value }
    @result.skipped[:docentes] += 1 unless changed
    changed
  end

  ##
  # Imports or updates a student (dicente) and creates their enrollment (matrícula) in a class.
  #
  # ==== Parameters
  # * +dicente_data+ - Hash containing student information (nome, email, matricula, curso, ocupacao, formacao)
  # * +turma+ - Turma object representing the class to enroll the student in
  #
  # ==== Returns
  # * nil
  #
  # ==== Side Effects
  # * Creates or updates Dicente record in database
  # * Creates or updates Matricula record linking student to class
  # * Sends password setup email to newly created students
  # * Updates import result counters
  #
  def import_dicente_and_matricula(dicente_data, turma)
    identifier = dicente_data['usuario'] || dicente_data['matricula']
    dicente = Dicente.find_or_initialize_by(identifier: identifier)

    return unless process_dicente(dicente, dicente_data, identifier)
    process_matricula(dicente, turma)
  end

  def process_dicente(dicente, dicente_data, identifier)
    if dicente.new_record?
      create_new_dicente(dicente, dicente_data, identifier)
    else
      update_existing_dicente(dicente, dicente_data, identifier)
    end
  end

  def create_new_dicente(dicente, dicente_data, identifier)
    assign_dicente_attributes(dicente, dicente_data)
    setup_dicente_activation(dicente)

    if dicente.save
      @result.created[:dicentes] += 1
      send_password_setup_email(dicente)
      true
    else
      @result.errors << "Erro ao criar dicente #{identifier}: #{dicente.errors.full_messages.join(', ')}"
      false
    end
  end

  def assign_dicente_attributes(dicente, dicente_data)
    dicente.nome = dicente_data['nome']
    dicente.email = dicente_data['email']
    dicente.matricula = dicente_data['matricula']
    dicente.curso = dicente_data['curso']
    dicente.ocupacao = dicente_data['ocupacao'] || 'dicente'
    dicente.formacao = dicente_data['formacao'] || 'graduando'
  end

  def setup_dicente_activation(dicente)
    dicente.pending_activation = true if dicente.respond_to?(:pending_activation)
    dicente.password_reset_token = SecureRandom.urlsafe_base64(32)
    dicente.password_reset_sent_at = Time.current
  end

  def update_existing_dicente(dicente, dicente_data, identifier)
    return true unless dicente_needs_update?(dicente, dicente_data)

    assign_dicente_attributes(dicente, dicente_data)

    if dicente.save
      @result.updated[:dicentes] += 1
      true
    else
      @result.errors << "Erro ao atualizar dicente #{identifier}: #{dicente.errors.full_messages.join(', ')}"
      false
    end
  end

  def dicente_needs_update?(dicente, dicente_data)
    attributes_to_check = {
      nome: dicente_data['nome'],
      email: dicente_data['email'],
      matricula: dicente_data['matricula'],
      curso: dicente_data['curso'],
      ocupacao: dicente_data['ocupacao'] || 'dicente',
      formacao: dicente_data['formacao'] || 'graduando'
    }

    changed = attributes_to_check.any? { |attr, new_value| dicente.send(attr) != new_value }
    @result.skipped[:dicentes] += 1 unless changed
    changed
  end

  def process_matricula(dicente, turma)
    matricula = Matricula.find_or_initialize_by(dicente: dicente, turma: turma)

    if matricula.new_record?
      create_new_matricula(matricula)
    else
      update_matricula_if_needed(matricula)
    end
  end

  def create_new_matricula(matricula)
    matricula.status = 'ativo'
    matricula.enrollment_date = Date.current

    if matricula.save
      @result.created[:matriculas] += 1
    else
      @result.errors << "Erro ao criar matrícula: #{matricula.errors.full_messages.join(', ')}"
    end
  end

  def update_matricula_if_needed(matricula)
    return @result.skipped[:matriculas] += 1 if matricula.status == 'ativo'

    matricula.status = 'ativo'
    if matricula.save
      @result.updated[:matriculas] += 1
    else
      @result.errors << "Erro ao atualizar matrícula: #{matricula.errors.full_messages.join(', ')}"
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

  def send_password_setup_email(user)
    # Enviar email (síncrono em test, assíncrono em production)
    if Rails.env.test?
      PasswordSetupMailer.setup_instructions(user).deliver_now
    else
      PasswordSetupMailer.setup_instructions(user).deliver_later
    end
  rescue StandardError => e
    # Log do erro mas não falha a importação
    Rails.logger.error("Erro ao enviar email de configuração de senha para #{user.email}: #{e.message}")
    @result.errors << "Email não enviado para #{user.email}: #{e.message}"
  end
end
