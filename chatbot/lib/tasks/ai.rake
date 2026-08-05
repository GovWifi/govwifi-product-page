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

  desc "Run every Evaluation and print a summary + save a report to tmp/"
  task evaluate: :environment do
    evals = Evaluation.order(:created_at)
    if evals.empty?
      warn "No evaluations. Run 'rake ai:seed_evaluations' or add via /evaluations."
      exit 1
    end

    report_path = Rails.root.join("tmp/eval-#{Time.current.strftime('%Y%m%d-%H%M%S')}.md")
    stats = Hash.new(0)
    lines = ["# Evaluation report — #{Time.current.iso8601}", ""]

    puts "Running #{evals.size} evaluations..."
    evals.each do |eval|
      EvaluationRunJob.perform_now(eval.id)
      run = eval.reload.latest_run
      status = run.presumed_correct? ? "PASS" : "FAIL"
      stats[status] += 1
      stats[:total] += 1
      puts "  [#{status}] #{eval.question}"
      puts "         #{run.latency_ms}ms  sources: #{run.citation_paths.join(', ')}"

      lines << "## #{eval.question}"
      lines << ""
      lines << "- Status: **#{status}**"
      lines << "- Latency: #{run.latency_ms} ms"
      lines << "- Tokens in/out: #{run.tokens_in}/#{run.tokens_out}"
      lines << "- Expected sources: #{eval.expected_sources.join(', ')}"
      lines << "- Retrieved sources: #{run.citation_paths.join(', ')}"
      lines << ""
      lines << "**Answer:**"
      lines << ""
      lines << run.actual_answer.to_s
      lines << ""
    end

    pct = stats[:total].zero? ? 0 : (stats["PASS"].to_f / stats[:total] * 100).round
    summary = "#{stats['PASS']}/#{stats[:total]} correct (#{pct}%)"
    puts "\n== Summary: #{summary} =="

    lines.insert(1, "**Summary: #{summary}**", "")
    File.write(report_path, lines.join("\n"))
    puts "Report: #{report_path}"
  end

  desc "Seed a starter evaluation set (matches docs/evaluation.md)"
  task seed_evaluations: :environment do
    seeds = [
      # Product-page questions
      { question: "How do I sign up for GovWifi?",
        expected_answer: "Visit www.wifi.service.gov.uk and enter your public-sector email address.",
        expected_sources: ["source/check-organisation-email-address.html.erb", "source/connect-to-govwifi.html.erb"] },
      { question: "How do I onboard my organisation?",
        expected_answer: "Visit the 'Offer GovWifi' flow and complete the memorandum of understanding.",
        expected_sources: ["source/offer-govwifi.html.erb", "source/memorandum-of-understanding.html.erb"] },
      { question: "How do I connect on an iPhone?",
        expected_sources: ["source/device-iphone-or-ipad.html.erb"] },
      { question: "How do I connect on Windows?",
        expected_sources: ["source/device-windows.html.erb"] },
      { question: "How do I troubleshoot Windows connection issues?",
        expected_sources: ["source/device-windows-troubleshoot.html.erb"] },

      # Tech-docs (Phase 2 — expected_sources point at tech-docs paths)
      { question: "How does GovWifi authentication work?",
        expected_sources: ["source/documentation/introduction.md", "source/documentation/set_up.md"] },
      { question: "How do certificates work?",
        expected_sources: ["source/certificate-rotation.html.md.erb"] },

      # Known-unknowns (assistant should decline)
      { question: "What's the weather in London today?",
        expected_answer: Answering::PromptBuilder::UNKNOWN_ANSWER,
        expected_sources: [],
        notes: "Known-unknown: out of scope, expect refusal." },
      { question: "How do I connect to Eduroam?",
        expected_answer: Answering::PromptBuilder::UNKNOWN_ANSWER,
        expected_sources: [],
        notes: "Known-unknown: different service, expect refusal." }
    ]

    added = 0
    seeds.each do |attrs|
      eval = Evaluation.find_or_initialize_by(question: attrs[:question])
      if eval.new_record?
        eval.assign_attributes(attrs)
        eval.save!
        added += 1
      end
    end

    puts "Seeded #{added} new evaluations (total: #{Evaluation.count})"
  end
end
