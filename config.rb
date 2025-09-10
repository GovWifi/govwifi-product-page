###
# Page options, layouts, aliases and proxies
###

# Per-page layout changes:
#
# With no layout
page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false

require_relative "./lib/tasks/fetch_orgs"

activate :directory_indexes

# With alternative layout
# page "/path/to/file.html", layout: :otherlayout

# Proxy pages (http://middlemanapp.com/basics/dynamic-pages/)
# proxy "/this-page-has-no-template.html", "/template-file.html", locals: {
#  which_fake_page: "Rendering a fake page with a local variable" }

set :relative_links, true

# General configuration

# Reload the browser automatically whenever files change
configure :development do
  activate :livereload
end

# Google analytics
# Analytics ID must be inside the single quotes as it’s string
configure :development do
  set :analytics, ""
#   set :analytics, "'UA-XXXXXXXX-X'"
end

# Insert your Google Analytics ID below
configure :build do
  set :analytics, ""
  activate :relative_assets
end

###
# Helpers
###

# Methods defined in the helpers block are available in templates
helpers do
  def subnav_active(url)
    current_page.url == url ? 'sub-navigation__item--active' : ''
  end

  def get_nav_active_class(url, root_scope)
    'govuk-header__navigation-item--active' if current_page.url.start_with? (root_scope or url)
  end
end

redirect "about-govwifi/connect-to-govwifi.html", to: "/connect-to-govwifi/"

redirect "help.html", to: "/get-help-connecting/"
redirect "privacy.html", to: "/privacy-notice/"
redirect "terms.html", to: "/terms-and-conditions/"

before_build do
  begin
    Tasks::FetchOrgs.call
  rescue => e
    puts "Failed to fetch organisations from S3: #{e.message}"
  end
end
