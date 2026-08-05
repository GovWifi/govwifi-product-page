class IndexDocumentJob < ApplicationJob
  queue_as :indexing

  def perform(source_type:, absolute_path:, relative_path:, url:)
    file = Ingest::Sources::LocalRepo::IndexableFile.new(
      source_type:   source_type,
      absolute_path: absolute_path,
      relative_path: relative_path,
      url:           url
    )
    result = Ingest::Pipeline.new.call(file)
    Rails.logger.info("[ingest] #{result.status}: #{source_type}/#{relative_path} (#{result.chunks_added} chunks)")
  end
end
