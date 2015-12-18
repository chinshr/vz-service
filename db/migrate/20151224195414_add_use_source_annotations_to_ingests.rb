class AddUseSourceAnnotationsToIngests < ActiveRecord::Migration
  def change
    add_column :ingests, :use_source_annotations, :boolean, default: false, null: false
  end
end
