class Rack::Attack
  # Cache backend defaults to memory in dev/test; production should
  # point this at Redis via ENV["REDIS_URL"] (Sidekiq's Redis is fine).
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  # /api/chat is the only expensive endpoint. Rate-limit per IP.
  # Tune limits via ENV to avoid a code deploy for a knob turn.
  chat_limit  = ENV.fetch("CHAT_RATE_LIMIT",  "20").to_i
  chat_period = ENV.fetch("CHAT_RATE_PERIOD", "60").to_i

  throttle("chat/ip", limit: chat_limit, period: chat_period) do |req|
    req.ip if req.path == "/api/chat" && req.post?
  end

  # JSON response for throttled requests (widget expects JSON, not HTML).
  self.throttled_responder = lambda do |request|
    retry_after = (request.env["rack.attack.match_data"] || {})[:period] || chat_period
    [
      429,
      { "Content-Type" => "application/json", "Retry-After" => retry_after.to_s },
      [{ error: "rate_limited", retry_after: retry_after }.to_json]
    ]
  end
end
