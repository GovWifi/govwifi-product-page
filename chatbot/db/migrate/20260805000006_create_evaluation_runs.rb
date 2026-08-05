class CreateEvaluationRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :evaluation_runs, id: :uuid do |t|
      t.references :evaluation, null: false, foreign_key: true, type: :uuid, index: true
      t.text     :actual_answer
      t.jsonb    :citations, default: []
      t.integer  :latency_ms
      t.integer  :tokens_in
      t.integer  :tokens_out
      t.string   :feedback           # "up" | "down" | null
      t.text     :feedback_notes
      t.datetime :ran_at

      t.timestamps
    end

    add_index :evaluation_runs, :ran_at
  end
end
