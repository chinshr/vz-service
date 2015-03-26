class AddRolesMaskToAdminUsers < ActiveRecord::Migration
  def change
    add_column :admin_users, :roles_mask, :integer
    add_index :admin_users, :roles_mask
  end
end
