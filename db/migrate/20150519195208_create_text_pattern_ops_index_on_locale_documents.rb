class CreateTextPatternOpsIndexOnLocaleDocuments < ActiveRecord::Migration
  def up
    remove_index :documents, :locale
    execute("CREATE INDEX documents_locale_with_text_pattern_ops ON documents(locale text_pattern_ops);")
  end

  def down
    execute("DROP INDEX documents_locale_with_text_pattern_ops;")
    add_index :documents, :locale
  end
end
