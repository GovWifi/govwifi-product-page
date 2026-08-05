class EvaluationRun < ApplicationRecord
  belongs_to :evaluation

  FEEDBACK_VALUES = %w[up down].freeze

  validates :feedback, inclusion: { in: FEEDBACK_VALUES }, allow_nil: true

  def feedback_up?
    feedback == "up"
  end

  def feedback_down?
    feedback == "down"
  end

  def citation_paths
    Array(citations).map { |c| c["path"] || c[:path] }.compact.uniq
  end

  # A run is "correct" if the human hasn't marked it down and (heuristically)
  # at least one expected source was retrieved. Used by the CLI summary.
  def presumed_correct?
    return false if feedback_down?
    return true  if feedback_up?
    expected = Array(evaluation.expected_sources)
    return true if expected.empty?
    (expected & citation_paths).any?
  end
end
