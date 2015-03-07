class AddCssHexColorToUsers < ActiveRecord::Migration
  def change
    add_column :users, :css_hex_color, :string
  end
end
