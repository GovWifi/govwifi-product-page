module Ingest
  # Load -> chunk -> embed -> upsert. Idempotent by raw_content_hash:
  # if the file's hash matches the stored Document, we skip embedding
  # entirely (the expensive step).
  class Pipeline
    Result = Data.define(:status, :document, :chunks_added)

    def initialize(chunker: Chunker.new, embedder: Embedder.new)
      @chunker  = chunker
      @embedder = embedder
    end

    def call(file)
      loaded = Loaders.for(file.absolute_path).call

      existing = Document.find_by(source_type: file.source_type, relative_path: file.relative_path)
      return Result.new(status: :skipped, document: existing, chunks_added: 0) if
        existing && existing.content_hash == loaded.raw_content_hash

      Document.transaction do
        document = existing || Document.new(
          source_type:   file.source_type,
          relative_path: file.relative_path
        )
        document.assign_attributes(
          title:        loaded.title,
          url:          file.url,
          content_hash: loaded.raw_content_hash,
          indexed_at:   Time.current
        )
        document.save!
        document.chunks.destroy_all

        chunk_attrs = @chunker.call(loaded.text)
        if chunk_attrs.empty?
          return Result.new(status: :indexed, document: document, chunks_added: 0)
        end

        embeddings = @embedder.call(chunk_attrs.map(&:content))

        chunk_attrs.zip(embeddings).each do |attrs, vector|
          Chunk.create!(
            document:      document,
            position:      attrs.position,
            heading_chain: attrs.heading_chain,
            content:       attrs.content,
            embedding:     vector,
            token_count:   attrs.token_count
          )
        end

        Result.new(
          status:       existing ? :updated : :indexed,
          document:     document,
          chunks_added: chunk_attrs.size
        )
      end
    end
  end
end
