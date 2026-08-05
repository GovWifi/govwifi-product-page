require "rails_helper"
require "rake"

RSpec.describe "ai:* rake tasks" do
  before(:all) do
    Rails.application.load_tasks unless Rake::Task.task_defined?("ai:evaluate")
  end

  before { Rake::Task["ai:evaluate"].reenable rescue nil
           Rake::Task["ai:seed_evaluations"].reenable rescue nil }

  describe "ai:seed_evaluations" do
    it "creates the starter evaluation set once and is idempotent on re-run" do
      expect { Rake::Task["ai:seed_evaluations"].invoke }.to change(Evaluation, :count).by_at_least(1)
      count_after_first = Evaluation.count

      Rake::Task["ai:seed_evaluations"].reenable
      Rake::Task["ai:seed_evaluations"].invoke
      expect(Evaluation.count).to eq(count_after_first)
    end
  end

  describe "ai:evaluate" do
    it "runs each Evaluation and writes a report file" do
      create(:evaluation, question: "How do I sign up?")
      fake_result = Answering::AnswerService::Result.new(
        answer: "Sign up online.", citations: [], latency_ms: 500, tokens_in: 100, tokens_out: 10
      )
      allow(Answering::AnswerService).to receive(:new).and_return(
        instance_double(Answering::AnswerService, call: fake_result)
      )

      expect { Rake::Task["ai:evaluate"].invoke }.to change(EvaluationRun, :count).by(1)

      report = Dir[Rails.root.join("tmp/eval-*.md")].max_by { |f| File.mtime(f) }
      expect(File.read(report)).to include("How do I sign up?")
    ensure
      Dir[Rails.root.join("tmp/eval-*.md")].each { |f| File.delete(f) }
    end
  end
end
