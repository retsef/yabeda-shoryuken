# frozen_string_literal: true

module Shoryuken::Worker
  class TestInlineExecutor < InlineExecutor
    class << self
      private

      def call(worker_class, sqs_msg)
        queue_name = worker_class.shoryuken_options_hash['queue']

        ::Shoryuken::Processor.process(queue_name, sqs_msg)
      end
    end
  end
end
