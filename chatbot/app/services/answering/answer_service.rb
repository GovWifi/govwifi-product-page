module Answering
  # Orchestrates: embed question -> retrieve chunks -> build prompt ->
  # call LLM -> return answer + citations.
  #
  # Two entry points:
  # - #call     for synchronous JSON responses (M3 non-streaming path)
  # - #stream   yields semantic events for SSE (M3 streaming path)
  #
  # When retrieval returns nothing above threshold, both methods
  # short-circuit with the unknown-answer phrase — the LLM is not called.
  class AnswerService
    Result = Data.define(:answer, :citations, :latency_ms, :tokens_in, :tokens_out)

    module Events
      Token     = Data.define(:delta)
      Citations = Data.define(:list)
      Done      = Data.define(:latency_ms, :tokens_in, :tokens_out)
    end

    def initialize(
      llm_client:     Llm::Client,
      retriever:      Retrieval::Retriever.new,
      prompt_builder: PromptBuilder.new
    )
      @llm_client     = llm_client
      @retriever      = retriever
      @prompt_builder = prompt_builder
    end

    def call(question:, history: [])
      started = monotonic_ms
      results = retrieve(question)

      return unknown_result(started) if results.empty?

      completion = @llm_client.chat(
        messages: @prompt_builder.call(question: question, retrieval_results: results, history: history)
      )

      Result.new(
        answer:     completion[:content],
        citations:  citations_for(results),
        latency_ms: monotonic_ms - started,
        tokens_in:  completion.dig(:usage, :input_tokens),
        tokens_out: completion.dig(:usage, :output_tokens)
      )
    end

    def stream(question:, history: [])
      started = monotonic_ms
      results = retrieve(question)

      if results.empty?
        yield Events::Token.new(delta: PromptBuilder::UNKNOWN_ANSWER)
        yield Events::Citations.new(list: [])
        yield Events::Done.new(latency_ms: monotonic_ms - started, tokens_in: 0, tokens_out: 0)
        return
      end

      completion = @llm_client.stream_chat(
        messages: @prompt_builder.call(question: question, retrieval_results: results, history: history)
      ) { |delta| yield Events::Token.new(delta: delta) }

      yield Events::Citations.new(list: citations_for(results))
      yield Events::Done.new(
        latency_ms: monotonic_ms - started,
        tokens_in:  completion.dig(:usage, :input_tokens) || 0,
        tokens_out: completion.dig(:usage, :output_tokens) || 0
      )
    end

    private

    def retrieve(question)
      query_vector = @llm_client.embed(texts: question).first
      @retriever.call(query_vector)
    end

    def citations_for(results)
      results
        .map(&:to_citation)
        .uniq { |c| [c[:source_type], c[:path]] }
    end

    def unknown_result(started_at)
      Result.new(
        answer:     PromptBuilder::UNKNOWN_ANSWER,
        citations:  [],
        latency_ms: monotonic_ms - started_at,
        tokens_in:  0,
        tokens_out: 0
      )
    end

    def monotonic_ms
      (Process.clock_gettime(Process::CLOCK_MONOTONIC) * 1000).to_i
    end
  end
end
