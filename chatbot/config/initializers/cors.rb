# The widget is embedded from product-page's origin (or preview URLs).
# Restrict CORS to configured origins so we don't accidentally expose
# /api/chat to the whole internet.

allowed = ENV.fetch(
  "CORS_ALLOWED_ORIGINS",
  "http://localhost:4567,http://localhost:3000"
).split(",").map(&:strip)

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*allowed)
    resource "/api/*",
             headers: :any,
             methods: [:get, :post, :options],
             max_age: 600
  end
end
