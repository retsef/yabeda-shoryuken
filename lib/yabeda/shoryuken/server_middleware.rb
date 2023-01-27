# frozen_string_literal: true

module Yabeda
  module Shoryuken
    # Client middleware to count number of enqueued jobs
    class ClientMiddleware
      def call(worker, queue, sqs_msg, _body)
        labels = Yabeda::Shoryuken.labelize(worker, sqs_msg, sqs_msg['queue'] || queue)
        Yabeda.shoryuken_jobs_enqueued_total.increment(labels)

        if sqs_msg['queue'] && sqs_msg['queue'] != queue
          labels = Yabeda::Shoryuken.labelize(worker, sqs_msg, queue)
          Yabeda.shoryuken_jobs_rerouted_total.increment({ from_queue: queue, to_queue: sqs_msg['queue'],
                                                           **labels.except(:queue), })
        end

        yield
      end
    end
  end
end
