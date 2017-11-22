# frozen_string_literal: true
require 'open3'
require 'open4'

def tmpdir
  File.expand_path('../../../tmp/dynamodb_server', __FILE__).tap do |dir|
    FileUtils.mkdir_p dir
  end
end

namespace :dynamodb do
  desc "Start DynamoDB server"
  task start: :download do
    Dir.chdir(tmpdir) do
      pid, _in, _out, _err = Open4.popen4 'java', '-Djava.library.path=./DynamoDBLocal_lib', '-jar', 'DynamoDBLocal.jar'
      $stderr.puts "DynamoDB running on 127.0.0.1:8000"
      Signal.trap("INT") do |signo|
        $stderr.print "Shutting down DynamoDB..."
        Process.kill(signo, pid)
      end
      Process.waitpid2 pid
      $stderr.puts "done."
    end
  end

  desc "Download and unpack DynamoDB server"
  task :download do
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

  desc "Clean up DynamoDB server"
  task :clean do
    FileUtils.rm_rf(tmpdir)
  end
end
