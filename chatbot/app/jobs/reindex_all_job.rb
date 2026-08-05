class ReindexAllJob < ApplicationJob
  queue_as :indexing

  def perform
    Ingest::Sources::LocalRepo.from_config.each do |repo|
      repo.each do |file|
        IndexDocumentJob.perform_later(
          source_type:   file.source_type,
          absolute_path: file.absolute_path,
          relative_path: file.relative_path,
          url:           file.url
        )
      end
    end
  end
end
