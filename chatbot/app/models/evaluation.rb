class Evaluation < ApplicationRecord
  has_many :evaluation_runs, -> { order(ran_at: :desc) }, dependent: :destroy

  validates :question, presence: true

  def latest_run
    evaluation_runs.first
  end

  def summary_status
    return :not_run unless latest_run
    latest_run.feedback&.to_sym || :awaiting_rating
  end
end
