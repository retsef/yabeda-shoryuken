# frozen_string_literal: true

module Yabeda
  module Shoryuken
    # Client middleware to count number of enqueued jobs
    class ClientMiddleware
      def call(options = {})
        queue = options[:queue_url]
        sqs_msg = ::Shoryuken::Message.new(::Shoryuken.client, queue, options)
        body = sqs_msg.body

        labels = Yabeda::Shoryuken.labelize(worker, sqs_msg, sqs_msg.queue_url || queue, body)
        Yabeda.shoryuken_jobs_enqueued_total.increment(labels)

        if sqs_msg.queue_url && sqs_msg.queue_url != queue
          labels = Yabeda::Shoryuken.labelize(worker, sqs_msg, queue, body)
          Yabeda.shoryuken_jobs_rerouted_total.increment({ from_queue: queue, to_queue: sqs_msg.queue_url,
                                                           **labels.except(:queue), })
        end

        yield
      end
    end
  end
end
