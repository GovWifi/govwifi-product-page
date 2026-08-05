class CreateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :documents, id: :uuid do |t|
      t.string :source_type,   null: false
      t.string :relative_path, null: false
      t.string :title
      t.string :url
      t.string :content_hash,  null: false
      t.datetime :indexed_at

      t.timestamps
    end

    add_index :documents, [:source_type, :relative_path], unique: true
    add_index :documents, :content_hash
  end
end
