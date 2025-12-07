class AddPendingActivationToUsuarios < ActiveRecord::Migration[8.1]
  def change
    add_column :usuarios, :pending_activation, :boolean, default: false, null: false
  end
end
