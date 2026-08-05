class EvaluationsController < ApplicationController
  def index
    @evaluations = Evaluation.order(created_at: :asc).includes(:evaluation_runs)
    @evaluation  = Evaluation.new
  end

  def create
    @evaluation = Evaluation.new(evaluation_params)

    if @evaluation.save
      redirect_to evaluations_path, notice: "Evaluation added."
    else
      @evaluations = Evaluation.order(created_at: :asc).includes(:evaluation_runs)
      render :index, status: :unprocessable_entity
    end
  end

  def run
    evaluation = Evaluation.find(params[:id])
    EvaluationRunJob.perform_now(evaluation.id)
    redirect_to evaluations_path, notice: "Run complete."
  end

  private

  def evaluation_params
    params
      .require(:evaluation)
      .permit(:question, :expected_answer, :notes, expected_sources: [])
      .then(&method(:normalise_expected_sources))
  end

  # Accept expected_sources as either a form-array or a comma-separated
  # string (the form uses the latter for a single text input).
  def normalise_expected_sources(attrs)
    return attrs unless attrs["expected_sources"].is_a?(Array) && attrs["expected_sources"].size == 1

    attrs.merge("expected_sources" => attrs["expected_sources"].first.to_s.split(",").map(&:strip).reject(&:empty?))
  end
end
