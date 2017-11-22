# frozen_string_literal: true
require 'open3'
require 'open4'
require 'aws-sdk-dynamodb'

class DynamoRunner
  def initialize
    yield self if block_given?
  end

  def tmpdir
    File.expand_path('../../../tmp/dynamodb_server', __FILE__).tap do |dir|
      FileUtils.mkdir_p dir
    end
  end

  def clean!
    FileUtils.rm_rf(tmpdir)
  end

  def download_and_extract
    unless File.exist?(File.expand_path('DynamoDBLocal.jar', tmpdir))
      Dir.chdir(tmpdir) do
        Open3.pipeline(
          %w[curl https://s3-us-west-2.amazonaws.com/dynamodb-local/dynamodb_local_latest.tar.gz],
          %w[tar xz]
        )
      end
    end
    true
  end

  def start
    download_and_extract
    Dir.chdir(tmpdir) do
      @pid, _in, _out, _err = Open4.popen4 'java', '-Djava.library.path=./DynamoDBLocal_lib', '-jar', 'DynamoDBLocal.jar'
      Signal.trap("INT") { |_signo| stop }
    end
  end

  def when_ready
    start if @pid.nil?
    client = Aws::DynamoDB::Client.new(endpoint: 'http://localhost:8000', http_open_timeout: 0.5, retry_limit: 0)
    retries = 0
    begin
      retries += 1
      client.list_tables
    rescue Seahorse::Client::NetworkingError
      sleep(1)
      raise "Timeout waiting for DynamoDB to spin up" if retries > 20
      retry
    end
    yield
  end

  def wait
    Process.waitpid2 @pid
  end

  def stop
    Process.kill('INT', @pid)
  end
end

desc "Full continuous integration"
task :ci do
  DynamoRunner.new do |db|
    begin
      db.when_ready do
        Rake::Task[:rubocop].invoke
        Rake::Task[:spec].invoke
      end
    ensure
      db.stop
      db.clean!
    end
  end
end

namespace :dynamodb do
  desc "Start DynamoDB server"
  task start: :download do
    DynamoRunner.new do |db|
      db.start
      db.when_ready do
        $stderr.puts "DynamoDB running on 127.0.0.1:8000"
      end
      db.wait
      $stderr.puts "Shutting down DynamoDB..."
    end
  end

  desc "Download and unpack DynamoDB server"
  task :download do
    DynamoRunner.new.download_and_extract
  end

  desc "Clean up DynamoDB server"
  task :clean do
    DynamoRunner.new.clean!
  end
end
