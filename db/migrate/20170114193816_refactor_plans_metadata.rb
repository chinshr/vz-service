class RefactorPlansMetadata < ActiveRecord::Migration
  def up
    remove_column :plans, :metadata

    add_column :plans, :config, :jsonb, default: {}, null: false
    add_index :plans, :config, using: :gin
  end

  def down
    remove_index :plans, :config
    remove_column :plans, :config

    add_column :plans, :metadata, :json, default: {}, null: false
  end
end
