# frozen_string_literal: true

require 'shoryuken'

require 'yabeda'
require 'yabeda/shoryuken/version'
require 'yabeda/shoryuken/client_middleware'
require 'yabeda/shoryuken/server_middleware'
require 'yabeda/shoryuken/config'

module Yabeda
  module Shoryuken
    LONG_RUNNING_JOB_RUNTIME_BUCKETS = [
      0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, # standard (from Prometheus)
      30, 60, 120, 300, 1800, 3600, 21_600, # Sidekiq tasks may be very long-running
    ].freeze

    def self.config
      @config ||= Config.new
    end

    Yabeda.configure do
      config = ::Yabeda::Shoryuken.config

      group :shoryuken

      counter :jobs_enqueued_total, tags: %i[queue worker], comment: "A counter of the total number of jobs shoryuken enqueued."
      counter :jobs_rerouted_total, tags: %i[from_queue to_queue worker], comment: "A counter of the total number of rerouted jobs shoryuken enqueued."

      if config.declare_process_metrics # defaults to +::Shoryuken.server?+
        counter   :jobs_executed_total,  tags: %i[queue worker], comment: "A counter of the total number of jobs shoryuken executed."
        counter   :jobs_success_total,   tags: %i[queue worker], comment: "A counter of the total number of jobs successfully processed by shoryuken."
        counter   :jobs_failed_total,    tags: %i[queue worker], comment: "A counter of the total number of jobs failed in shoryuken."

        gauge     :running_job_runtime,  tags: %i[queue worker], aggregation: :max, unit: :seconds,
                  comment: "How long currently running jobs are running (useful for detection of hung jobs)"

        histogram :job_latency, comment: "The job latency, the difference in seconds between enqueued and running time",
                  unit: :seconds, per: :job,
                  tags: %i[queue worker],
                  buckets: LONG_RUNNING_JOB_RUNTIME_BUCKETS
        histogram :job_runtime, comment: "A histogram of the job execution time.",
                  unit: :seconds, per: :job,
                  tags: %i[queue worker],
                  buckets: LONG_RUNNING_JOB_RUNTIME_BUCKETS
      end

      # Metrics not specific for current Shoryuken process, but representing state of the whole Shoryuken installation (queues, processes, etc)
      # You can opt-out from collecting these by setting YABEDA_SIDEKIQ_COLLECT_CLUSTER_METRICS to falsy value (+no+ or +false+)
      if config.collect_cluster_metrics # defaults to +::Shoryuken.server?+
        gauge     :queue_latency,        tags: %i[queue], aggregation: :most_recent,
                  comment: "The queue latency, the difference in seconds since the oldest job in the queue was enqueued"
      end

      collect do
        Yabeda::Shoryuken.track_max_job_runtime if ::Shoryuken.server?

        next unless config.collect_cluster_metrics

        ::Shoryuken::Queue.all.each do |queue|
          shoryuken_queue_latency.set({ queue: queue.name }, queue.latency)
        end
      end
    end

    ::Shoryuken.configure_server do |config|
      config.server_middleware do |chain|
        chain.add ServerMiddleware
      end
      config.client_middleware do |chain|
        chain.add ClientMiddleware
      end
    end

    ::Shoryuken.configure_client do |config|
      config.client_middleware do |chain|
        chain.add ClientMiddleware
      end
    end

    class << self
      def labelize(worker, job, queue)
        { queue: queue, worker: worker_class(worker, job) }
      end

      def worker_class(worker, job)
        if defined?(ActiveJob::QueueAdapters::ShoryukenAdapter::JobWrapper)
          if worker.is_a?(ActiveJob::QueueAdapters::ShoryukenAdapter::JobWrapper) || worker == ActiveJob::QueueAdapters::ShoryukenAdapter::JobWrapper
            return job["wrapped"].to_s
          end
        end
        (worker.is_a?(String) || worker.is_a?(Class) ? worker : worker.class).to_s
      end

      def custom_tags(worker, job)
        return {} unless worker.respond_to?(:yabeda_tags)

        worker.method(:yabeda_tags).arity.zero? ? worker.yabeda_tags : worker.yabeda_tags(*job["args"])
      end

      # Hash of hashes containing all currently running jobs' start timestamps
      # to calculate maximum durations of currently running not yet completed jobs
      # { { queue: "default", worker: "SomeJob" } => { "jid1" => 100500, "jid2" => 424242 } }
      attr_accessor :jobs_started_at

      def track_max_job_runtime
        now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        ::Yabeda::Shoryuken.jobs_started_at.each do |labels, jobs|
          oldest_job_started_at = jobs.values.min
          oldest_job_duration = oldest_job_started_at ? (now - oldest_job_started_at).round(3) : 0
          Yabeda.shoryuken.running_job_runtime.set(labels, oldest_job_duration)
        end
      end
    end

    self.jobs_started_at = Concurrent::Map.new { |hash, key| hash[key] = Concurrent::Map.new }
  end
end
