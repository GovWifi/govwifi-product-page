require 'rspec/core/rake_task'
require_relative './lib/tasks/fetch_orgs'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :data do
  desc "Fetch organisations from S3 and write to data/organisations.yml"
  task :fetch_orgs do
    Tasks::FetchOrgs.call
  end
end
