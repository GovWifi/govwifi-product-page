module Ingest
  # Thin wrapper over Llm::Client.embed. The client already batches per
  # provider limits and retries on transient errors — this class exists
  # to give the pipeline an injectable seam for tests.
  class Embedder
    def initialize(llm_client: Llm::Client)
      @llm_client = llm_client
    end

    def call(texts)
      return [] if texts.empty?
      @llm_client.embed(texts: texts)
    end
  end
end
