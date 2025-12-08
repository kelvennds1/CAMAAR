require 'rails_helper'

RSpec.describe PasswordSetupMailer, type: :mailer do
  describe '#setup_instructions' do
    let(:user) do
      create(:dicente,
             nome: 'João Silva',
             email: 'joao@example.com',
             password_reset_token: 'sample-token-123',
             pending_activation: true)
    end

    let(:mail) { PasswordSetupMailer.setup_instructions(user) }

    it 'renders the subject' do
      expect(mail.subject).to include('senha')
      expect(mail.subject).to include('CAMAAR')
    end

    it 'sends to the correct email address' do
      expect(mail.to).to eq([user.email])
    end

    it 'sends from the correct sender' do
      expect(mail.from).to eq(['noreply@camaar.unb.br'])
    end

    it 'includes user name in body' do
      expect(mail.body.encoded).to include(user.nome)
    end

    it 'includes password setup link in body' do
      expect(mail.body.encoded).to include('password_setup')
      expect(mail.body.encoded).to include(user.password_reset_token)
    end

    it 'includes user email in body' do
      expect(mail.body.encoded).to include(user.email)
    end

    it 'mentions the link validity period' do
      expect(mail.body.encoded).to match(/24 horas/i)
    end

    context 'with HTML version' do
      it 'includes clickable link' do
        html_part = mail.body.parts.find { |p| p.content_type.include?('text/html') }
        expect(html_part.body.encoded).to include('<a href=')
      end
    end

    context 'with text version' do
      it 'includes plain text link' do
        text_part = mail.body.parts.find { |p| p.content_type.include?('text/plain') }
        expect(text_part.body.encoded).to include('password_setup')
      end
    end
  end
end
