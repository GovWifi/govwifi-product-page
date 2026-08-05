module Api
  class ChatController < BaseController
    # SSE streaming needs Live so response.stream is available. The
    # non-streaming branch still returns a normal JSON body — Live
    # doesn't preclude that.
    include ActionController::Live

    def create
      question = params.require(:question).to_s.strip
      history  = extract_history(params[:history])

      if streaming?
        stream(question, history)
      else
        render_json(question, history)
      end
    end

    private

    def streaming?
      request.headers["Accept"].to_s.include?("text/event-stream")
    end

    def render_json(question, history)
      result = Answering::AnswerService.new.call(question: question, history: history)

      render json: {
        answer:     result.answer,
        citations:  result.citations,
        latency_ms: result.latency_ms,
        tokens:     { input: result.tokens_in, output: result.tokens_out }
      }
    end

    def stream(question, history)
      response.headers["Content-Type"]     = "text/event-stream"
      response.headers["Cache-Control"]    = "no-cache"
      response.headers["X-Accel-Buffering"] = "no"

      sse = ActionController::Live::SSE.new(response.stream)

      begin
        Answering::AnswerService.new.stream(question: question, history: history) do |event|
          write_sse(sse, event)
        end
      rescue IOError, ActionController::Live::ClientDisconnected
        # Client closed the tab — expected.
      rescue => e
        Rails.logger.error("[chat] stream error: #{e.class}: #{e.message}")
        sse.write({ error: "internal_error" }, event: "error")
      ensure
        sse.close
      end
    end

    def write_sse(sse, event)
      case event
      when Answering::AnswerService::Events::Token
        sse.write({ delta: event.delta }, event: "token")
      when Answering::AnswerService::Events::Citations
        sse.write({ citations: event.list }, event: "citations")
      when Answering::AnswerService::Events::Done
        sse.write(
          { latency_ms: event.latency_ms, tokens: { input: event.tokens_in, output: event.tokens_out } },
          event: "done"
        )
      end
    end

    def extract_history(raw)
      Array(raw).map do |m|
        role    = m.is_a?(ActionController::Parameters) ? m[:role]    : (m["role"]    || m[:role])
        content = m.is_a?(ActionController::Parameters) ? m[:content] : (m["content"] || m[:content])
        { role: role.to_s, content: content.to_s }
      end
    end
  end
end
