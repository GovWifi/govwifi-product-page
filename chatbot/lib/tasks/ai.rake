namespace :ai do
  desc "Index all configured documentation sources (see config/ai_sources.yml)"
  task index_docs: :environment do
    async = ENV["ASYNC"] == "1"
    stats = Hash.new(0)

    puts "Loading sources from config/ai_sources.yml..."
    repos = Ingest::Sources::LocalRepo.from_config
    if repos.empty?
      warn "No sources configured. Add entries to config/ai_sources.yml."
      exit 1
    end

    repos.each do |repo|
      files = repo.each.to_a
      source_type = files.first&.source_type || "(unknown)"
      puts "\n== #{source_type}: #{files.size} candidate files =="

      files.each do |file|
        if async
          IndexDocumentJob.perform_later(
            source_type:   file.source_type,
            absolute_path: file.absolute_path,
            relative_path: file.relative_path,
            url:           file.url
          )
          stats[:enqueued] += 1
          puts "  enqueued  #{file.relative_path}"
        else
          begin
            result = Ingest::Pipeline.new.call(file)
            stats[result.status] += 1
            puts "  #{result.status.to_s.rjust(8)}  #{file.relative_path} (#{result.chunks_added} chunks)"
          rescue => e
            stats[:errored] += 1
            puts "   errored  #{file.relative_path}: #{e.class}: #{e.message}"
          end
        end
      end
    end

    puts "\n== Summary =="
    stats.each { |k, v| puts "  #{k}: #{v}" }
  end

  desc "Show what files would be indexed, without hitting the LLM"
  task dry_run: :environment do
    Ingest::Sources::LocalRepo.from_config.each do |repo|
      files = repo.each.to_a
      source_type = files.first&.source_type || "(unknown)"
      puts "\n== #{source_type}: #{files.size} files =="
      files.each { |f| puts "  #{f.relative_path} -> #{f.url}" }
    end
  end
end
