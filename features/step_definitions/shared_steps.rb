# frozen_string_literal: true

Então('devo ver a mensagem {string}') do |texto|
  expect(page).to have_content(texto)
end
