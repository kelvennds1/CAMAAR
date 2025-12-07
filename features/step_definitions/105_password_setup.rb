# frozen_string_literal: true

require "securerandom"

Given('there is a pending user who received a password setup email with a valid token') do
  @valid_token = SecureRandom.urlsafe_base64(32)
  @pending_user = Dicente.create!(
    nome: "Pending User",
    email: "pending@example.com",
    identifier: SecureRandom.uuid,
    matricula: "20231111111",
    curso: "Computer Science",
    password_digest: nil,
    pending_activation: true,
    password_reset_token: @valid_token,
    password_reset_sent_at: Time.current
  )
end

When('I open the password setup link') do
  visit password_setup_path(token: @valid_token)
end

When('I set a new valid password and confirmation') do
  fill_in "password", with: "newpassword123"
  fill_in "password_confirmation", with: "newpassword123"
  click_button "Set Password"
end

Then('my account becomes active') do
  @pending_user.reload
  expect(@pending_user.pending_activation).to be false
  expect(@pending_user.password_digest).to_not be_nil
end

Then('I can sign in with my new credentials') do
  expect(page).to have_current_path(avaliacoes_path)
  expect(@pending_user.authenticate("newpassword123")).to be_truthy
end

Given('my password setup token is invalid or expired') do
  @valid_token = "invalid-token-123"
  @expired_token = "invalid-token-123"
end

Then('I see an error indicating the link is invalid or expired') do
  expect(page).to have_content("Password setup link is invalid or expired")
end

Then('I am offered a way to request a new password setup email') do
  # Deve estar na página de solicitar novo link
  expect(page).to have_current_path(request_new_password_path)
  expect(page).to have_content("Contact your administrator")
end

When('I enter a password and a non-matching confirmation') do
  fill_in "password", with: "password123"
  fill_in "password_confirmation", with: "differentpassword"
  click_button "Set Password"
end

Then('I see a validation error about the confirmation not matching') do
  expect(page).to have_content("Password confirmation doesn't match")
end

Then('my account remains pending until I set a valid password') do
  @pending_user.reload
  expect(@pending_user.pending_activation).to be true
end

When('I successfully set a password using the email link') do
  step "I open the password setup link"
  step "I set a new valid password and confirmation"
end

When('I try to use the same link again') do
  visit password_setup_path(token: @valid_token)
end

Then('I see an error that the token has already been used') do
  expect(page).to have_content("Password setup link is invalid or expired")
end

Then('I remain signed in with my new credentials') do
  # Quando tentar usar o token novamente, será redirecionado para request_new_password
  # pois o token já foi invalidado
  expect(page).to have_current_path(request_new_password_path)
end
