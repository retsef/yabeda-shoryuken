# frozen_string_literal: true

require 'bundler/setup'
require 'shoryuken'

module Shoryuken::CLI; end # Fake that we're a worker to test worker-specific things
require 'yabeda/shoryuken'
require 'yabeda/rspec'

require_relative 'support/custom_metrics'
require_relative 'support/jobs'
require_relative 'support/shoryuken_inline_middlewares'
require_relative 'support/shoryuken_inline_processor'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.mock_with :rspec

  Kernel.srand config.seed
  config.order = :random

  config.before(:all) do
    Yabeda::Shoryuken.config.declare_process_metrics = true
    Yabeda::Shoryuken.config.collect_cluster_metrics = true

    Shoryuken.options[:concurrency] = 1
    Shoryuken.options[:delay]       = 1.0
    Shoryuken.options[:timeout]     = 1
    Shoryuken.options[:daemon]      = nil
    Shoryuken.options[:logfile]     = nil
    Shoryuken.options[:queues]      = nil

    Shoryuken.active_job_queue_name_prefixing = false
    Aws.config[:stub_responses] = true

    Shoryuken.sqs_client_receive_message_opts.clear
    Shoryuken.cache_visibility_timeout = false

    Shoryuken.worker_executor = Shoryuken::Worker::TestInlineExecutor
  end

  config.before do
    Shoryuken.sqs_client = instance_double('Aws::Sqs::Client').tap do |client|

      %w[default sample_plain sample_long_running sample_complex failing_plain].each do |queue_name|
        allow(client).to receive(:get_queue_url)
          .with({ queue_name: queue_name })
          .and_return instance_double('Aws::SQS::Types::GetQueueUrlResult', queue_url: queue_name)

        allow(client).to receive(:get_queue_attributes)
          .with({ attribute_names: ['All'], queue_url: queue_name })
          .and_return instance_double('Aws::SQS::Types::GetQueueAttributesResult', attributes: {})
      end

      allow(client).to receive(:send_message)
      allow(client).to receive(:receive_message)
    end
  end

  config.after(:all) do
    Shoryuken.worker_executor = Shoryuken::Worker::DefaultExecutor
  end
end
