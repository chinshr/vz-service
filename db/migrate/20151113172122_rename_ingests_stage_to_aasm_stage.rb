class RenameIngestsStageToAasmStage < ActiveRecord::Migration
  def change
    rename_column :ingests, :stage, :aasm_stage
  end
end
