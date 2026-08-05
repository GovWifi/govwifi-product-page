class EvaluationRunJob < ApplicationJob
  queue_as :default

  def perform(evaluation_id)
    evaluation = Evaluation.find(evaluation_id)

    result = Answering::AnswerService.new.call(question: evaluation.question)

    evaluation.evaluation_runs.create!(
      actual_answer: result.answer,
      citations:     result.citations.map(&:deep_stringify_keys),
      latency_ms:    result.latency_ms,
      tokens_in:     result.tokens_in,
      tokens_out:    result.tokens_out,
      ran_at:        Time.current
    )
  end
end
