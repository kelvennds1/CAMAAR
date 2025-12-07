# frozen_string_literal: true

Então('devo ver a mensagem {string}') do |texto|
  if texto.include?('xx')
    pattern = Regexp.new(Regexp.escape(texto).gsub('xx', '\\d+'))
    expect(page).to have_text(pattern)
  else
    expect(page).to have_content(texto)
  end
end

Então('devo ver a mensagem que contém {string}') do |texto_parcial|
  expect(page).to have_content(texto_parcial)
end
