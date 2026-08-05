class CreateChunks < ActiveRecord::Migration[8.1]
  def change
    create_table :chunks, id: :uuid do |t|
      t.references :document, null: false, foreign_key: true, type: :uuid, index: true
      t.integer :position, null: false
      t.string :heading_chain
      t.text :content, null: false
      t.column :embedding, "vector(1536)"
      t.integer :token_count

      t.timestamps
    end

    add_index :chunks, [:document_id, :position], unique: true
    add_index :chunks, :embedding, using: :hnsw, opclass: :vector_cosine_ops
  end
end
