class AddPasswordResetToUsuarios < ActiveRecord::Migration[8.1]
  def change
    add_column :usuarios, :password_reset_token, :string
    add_column :usuarios, :password_reset_sent_at, :datetime
    add_index :usuarios, :password_reset_token, unique: true
  end
end
