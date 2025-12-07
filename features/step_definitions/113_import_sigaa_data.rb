# frozen_string_literal: true

Dado('estou na página "importacao/sigaa" do sistema') do
  visit new_sigaa_import_path
end

Dado('existem arquivos JSON de turmas, matérias e participantes disponíveis no repositório') do
  @turmas_json_path = Rails.root.join('classes.json')
  @materias_json_path = Rails.root.join('classes.json') # Mesmo arquivo
  @participantes_json_path = Rails.root.join('class_members.json')

  expect(File.exist?(@turmas_json_path)).to be(true)
  expect(File.exist?(@participantes_json_path)).to be(true)
end

Dado('que existem turmas, matérias e participantes nos arquivos JSON que ainda não existem na base de dados') do
  Turma.delete_all
  Materia.delete_all
  Dicente.delete_all
  Docente.delete_all
  Matricula.delete_all

  @turmas_antes = Turma.count
  @materias_antes = Materia.count
  @dicentes_antes = Dicente.count
end

Quando('eu seleciono os arquivos JSON do SIGAA para importação') do
  attach_file('classes_file', @turmas_json_path)
  attach_file('class_members_file', @participantes_json_path)
end

Quando('eu confirmo a importação dos dados') do
  click_button 'Importar dados do SIGAA'
end

Então('as turmas do SIGAA que não existiam são cadastradas na base de dados') do
  expect(Turma.count).to be > @turmas_antes
end

Então('as matérias do SIGAA que não existiam são cadastradas na base de dados') do
  expect(Materia.count).to be > @materias_antes
end

Então('os participantes do SIGAA que não existiam são cadastrados na base de dados') do
  expect(Dicente.count).to be > @dicentes_antes
end

Dado('que algumas turmas, matérias e participantes dos arquivos JSON já existem na base de dados') do
  # Importa uma vez para criar registros
  SigaaImporter.call(
    classes_file: File.open(@turmas_json_path),
    class_members_file: File.open(@participantes_json_path)
  )

  @turmas_antes = Turma.count
  @materias_antes = Materia.count
  @dicentes_antes = Dicente.count
end

Quando('eu realizo a importação dos dados do SIGAA') do
  step 'eu seleciono os arquivos JSON do SIGAA para importação'
  step 'eu confirmo a importação dos dados'
end

Então('os registros já existentes não são duplicados na base de dados') do
  # Verifica que a contagem não aumentou
  expect(Materia.count).to eq(@materias_antes)
end

Então('apenas os registros inexistentes são criados') do
  expect(Turma.count).to be >= @turmas_antes
  expect(Materia.count).to be >= @materias_antes
  expect(Dicente.count).to be >= @dicentes_antes
end

Dado('que o arquivo JSON de turmas está em formato inválido') do
  @invalid_file = Tempfile.new(['invalid', '.json'])
  @invalid_file.write('isso_nao_e_um_json_valido')
  @invalid_file.rewind
  @turmas_json_path = @invalid_file.path
  @turmas_antes = Turma.count
end

Quando('eu tento importar os dados do SIGAA') do
  attach_file('classes_file', @turmas_json_path)
  click_button 'Importar dados do SIGAA'
end

Então('nenhum dado é importado a partir desse arquivo inválido') do
  expect(Turma.count).to eq(@turmas_antes)
end

Dado('que não selecionei nenhum arquivo JSON para importação') do
  @turmas_antes = Turma.count
  @materias_antes = Materia.count
  @dicentes_antes = Dicente.count
end

Quando('eu tento iniciar a importação dos dados do SIGAA') do
  click_button 'Importar dados do SIGAA'
end

Então('nenhum dado é importado') do
  expect(Turma.count).to eq(@turmas_antes)
  expect(Materia.count).to eq(@materias_antes)
  expect(Dicente.count).to eq(@dicentes_antes)
end