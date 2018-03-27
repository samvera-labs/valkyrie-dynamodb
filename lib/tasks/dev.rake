# frozen_string_literal: true
require 'aws-sdk-dynamodb'

desc "Full continuous integration"
task :ci do
  Rake::Task[:rubocop].invoke
  Rake::Task['docker:spec'].invoke
end
