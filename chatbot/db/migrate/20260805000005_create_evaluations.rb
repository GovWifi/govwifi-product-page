class CreateEvaluations < ActiveRecord::Migration[8.1]
  def change
    create_table :evaluations, id: :uuid do |t|
      t.text   :question,         null: false
      t.text   :expected_answer
      t.string :expected_sources, array: true, default: []
      t.text   :notes

      t.timestamps
    end
  end
end
