# frozen_string_literal: true

module Yabeda
  module Shoryuken
    # Client middleware to count number of enqueued jobs
    class ClientMiddleware
      def call(options = {})
        queue_url = options[:queue_url]

        Yabeda.shoryuken_messages_enqueued_total.increment({ queue: queue_url })

        yield
      end
    end
  end
end
