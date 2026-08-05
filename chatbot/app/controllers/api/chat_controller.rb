module Api
  class ChatController < BaseController
    def create
      question = params.require(:question).to_s.strip
      history  = extract_history(params[:history])

      result = Answering::AnswerService.new.call(question: question, history: history)

      render json: {
        answer:     result.answer,
        citations:  result.citations,
        latency_ms: result.latency_ms,
        tokens:     { input: result.tokens_in, output: result.tokens_out }
      }
    end

    private

    def extract_history(raw)
      Array(raw).map { |m|
        role    = m.is_a?(ActionController::Parameters) ? m[:role]    : (m["role"]    || m[:role])
        content = m.is_a?(ActionController::Parameters) ? m[:content] : (m["content"] || m[:content])
        { role: role.to_s, content: content.to_s }
      }
    end
  end
end
