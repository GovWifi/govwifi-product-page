require "rails_helper"

RSpec.describe "widget demo & delivery", type: :request do
  describe "GET /widget_demo" do
    it "renders a page that mounts widget.js via a script tag" do
      get "/widget_demo"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('src="/widget.js"')
      expect(response.body).to include("Widget Demo")
    end

    it "returns 404 in production" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
      get "/widget_demo"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /widget.js" do
    it "serves the widget bundle" do
      get "/widget.js"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("govwifiAssistant")
      expect(response.body).to include(".gwa-container")
    end

    it "exposes the SSE-consuming askStream function" do
      get "/widget.js"

      expect(response.body).to include("text/event-stream")
      expect(response.body).to include("askStream")
    end
  end
end
