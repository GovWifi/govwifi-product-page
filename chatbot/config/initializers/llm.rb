Rails.application.config.llm = ActiveSupport::OrderedOptions.new.tap do |c|
  c.chat_provider  = ENV.fetch("LLM_CHAT_PROVIDER",  "anthropic").to_sym
  c.embed_provider = ENV.fetch("LLM_EMBED_PROVIDER", "openai").to_sym
  c.embed_dimensions = ENV.fetch("OPENAI_EMBED_DIMENSIONS", 1536).to_i
end
