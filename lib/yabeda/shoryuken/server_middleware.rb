# frozen_string_literal: true

module Yabeda
  module Shoryuken
    # Shoryuken worker middleware
    class ServerMiddleware
      # rubocop: disable Metrics/AbcSize, Style/ExplicitBlockArgument
      def call(worker, queue, sqs_msg, body)
        jid = SecureRandom.uuid

        custom_tags = Yabeda::Shoryuken.custom_tags(worker, sqs_msg).to_h
        labels = Yabeda::Shoryuken.labelize(worker.class, sqs_msg, queue, body).merge(custom_tags)
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        begin
          Yabeda::Shoryuken.jobs_started_at[labels][jid] = start
          Yabeda.with_tags(**custom_tags) do
            yield
          end

          Yabeda.shoryuken_jobs_success_total.increment(labels)
        rescue Exception # rubocop: disable Lint/RescueException
          Yabeda.shoryuken_jobs_failed_total.increment(labels)
          raise
        ensure
          Yabeda.shoryuken_job_runtime.measure(labels, elapsed(start))
          Yabeda.shoryuken_jobs_executed_total.increment(labels)
          Yabeda::Shoryuken.jobs_started_at[labels].delete(jid)
        end
      end
      # rubocop: enable Metrics/AbcSize, Style/ExplicitBlockArgument

      private

      def elapsed(start)
        (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start).round(3)
      end
    end
  end
end
