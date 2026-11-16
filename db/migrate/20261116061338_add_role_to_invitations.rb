class AddRoleToInvitations < ActiveRecord::Migration[8.1]
  def change
    add_column :invitations, :role, :integer
  end
end
