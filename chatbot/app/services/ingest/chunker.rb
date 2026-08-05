module Ingest
  # Heading-aware recursive chunker.
  #
  # Strategy:
  # 1. Split the document into sections at markdown H1..H6 lines,
  #    maintaining a "heading chain" breadcrumb per section.
  # 2. Within a section, greedy-pack paragraphs into chunks up to
  #    TARGET_CHARS. Overlap the tail of the previous chunk into the
  #    next to preserve context across boundaries.
  # 3. If a single paragraph exceeds TARGET_CHARS, emit it as its own
  #    chunk (we don't split mid-sentence in MVP).
  #
  # Token counts are estimated at ~4 chars/token; good enough for
  # ordering + retrieval scoring. Swap for tiktoken later if needed.
  class Chunker
    TARGET_TOKENS   = 800
    OVERLAP_TOKENS  = 100
    CHARS_PER_TOKEN = 4

    TARGET_CHARS  = TARGET_TOKENS  * CHARS_PER_TOKEN
    OVERLAP_CHARS = OVERLAP_TOKENS * CHARS_PER_TOKEN

    ChunkAttrs = Data.define(:position, :heading_chain, :content, :token_count)

    def call(text)
      sections = split_by_headings(text)
      chunks   = []

      sections.each do |section|
        chunks.concat(chunk_section(section, start_position: chunks.size))
      end

      chunks
    end

    private

    def split_by_headings(text)
      sections     = []
      chain        = []
      buffer       = +""

      text.each_line do |line|
        if (match = line.match(/\A(#{1,6})\s+(.+)/))
          sections << { heading_chain: chain.dup, body: buffer.strip } unless buffer.strip.empty?

          level    = Regexp.last_match(1).length
          heading  = Regexp.last_match(2).strip
          chain    = chain.first(level - 1)
          chain[level - 1] = heading
          buffer   = +""
        else
          buffer << line
        end
      end
      sections << { heading_chain: chain.dup, body: buffer.strip } unless buffer.strip.empty?

      sections
    end

    def chunk_section(section, start_position:)
      heading_prefix = section[:heading_chain].join(" > ")
      body           = section[:body]

      return [] if body.empty?

      combined = heading_prefix.empty? ? body : "#{heading_prefix}\n\n#{body}"
      if combined.length <= TARGET_CHARS
        return [attrs(start_position, heading_prefix, combined)]
      end

      chunks     = []
      paragraphs = body.split(/\n\n+/).reject { |p| p.strip.empty? }
      buffer     = +""

      paragraphs.each do |paragraph|
        candidate_length = buffer.length + paragraph.length + 2
        if candidate_length > TARGET_CHARS && !buffer.empty?
          chunks << attrs(start_position + chunks.size, heading_prefix, build_chunk(heading_prefix, buffer))
          buffer = overlap_tail(buffer) + paragraph
        else
          buffer << (buffer.empty? ? paragraph : "\n\n#{paragraph}")
        end
      end

      chunks << attrs(start_position + chunks.size, heading_prefix, build_chunk(heading_prefix, buffer)) unless buffer.strip.empty?
      chunks
    end

    def build_chunk(heading_prefix, body)
      heading_prefix.empty? ? body.strip : "#{heading_prefix}\n\n#{body.strip}"
    end

    def overlap_tail(text)
      return "" if text.length <= OVERLAP_CHARS
      "#{text[-OVERLAP_CHARS..]}\n\n"
    end

    def attrs(position, heading_prefix, content)
      ChunkAttrs.new(
        position:      position,
        heading_chain: heading_prefix,
        content:       content,
        token_count:   (content.length / CHARS_PER_TOKEN.to_f).round
      )
    end
  end
end
