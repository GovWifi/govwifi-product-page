class EvaluationRunsController < ApplicationController
  def feedback
    run = EvaluationRun.find(params[:id])

    # Toggle: clicking the currently-set value clears it.
    new_value = params[:feedback].to_s
    new_value = nil if run.feedback == new_value

    run.update(feedback: new_value, feedback_notes: params[:feedback_notes])
    redirect_to evaluations_path
  end
end
