# frozen_string_literal: true

module ShoryukenTestingInlineWithMiddlewares
  def push(job)
    return super unless Shoryuken::Testing.inline?

    job = Shoryuken.load_json(Shoryuken.dump_json(job))
    job['jid'] ||= SecureRandom.hex(12)
    job_class = Shoryuken::Testing.constantize(job['class'])
    job_instance = job_class.new
    queue = (job_instance.shoryuken_options_hash || {}).fetch('queue', 'default')
    Shoryuken.server_middleware.invoke(job_instance, job, queue) do
      job_instance.perform(*job['args'])
    end
    job['jid']
  end
end

Shoryuken::Client.prepend(ShoryukenTestingInlineWithMiddlewares)
