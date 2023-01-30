# frozen_string_literal: true

RSpec.describe Yabeda::Shoryuken do
  it 'has a version number' do
    expect(Yabeda::Shoryuken::VERSION).not_to be nil
  end

  it 'configures middlewares' do
    expect(Shoryuken.client_middleware.entries).to include(have_attributes(klass: Yabeda::Shoryuken::ClientMiddleware))
  end

  let(:sample_body) { SecureRandom.uuid }

  before do

  end

  describe 'plain Shoryuken jobs' do
    it 'counts enqueues' do
      Yabeda.shoryuken.messages_enqueued_total.values.clear # This is a hack

      Shoryuken::Client.queues('default').send_message(message_body: sample_body)

      expect(Yabeda.shoryuken.messages_enqueued_total.values).to include(
        { queue: 'default' } => 1,
      )
    end

    it 'measures runtime' do
      Yabeda.shoryuken.jobs_executed_total.values.clear   # This is a hack
      Yabeda.shoryuken.jobs_success_total.values.clear    # This is a hack
      Yabeda.shoryuken.jobs_failed_total.values.clear     # This is a hack
      Yabeda.shoryuken.job_runtime.values.clear           # This is a hack also

      SamplePlainJob.perform_async(sample_body)
      SamplePlainJob.perform_async(sample_body)
      begin
        FailingPlainJob.perform_async(sample_body)
      rescue Exception
        nil
      end

      expect(Yabeda.shoryuken.jobs_executed_total.values).to eq(
        { queue: 'sample_plain', worker: 'SamplePlainJob' } => 2,
        { queue: 'failing_plain', worker: 'FailingPlainJob' } => 1,
      )
      expect(Yabeda.shoryuken.jobs_success_total.values).to eq(
        { queue: 'sample_plain', worker: 'SamplePlainJob' } => 2,
      )
      expect(Yabeda.shoryuken.jobs_failed_total.values).to eq(
        { queue: 'failing_plain', worker: 'FailingPlainJob' } => 1,
      )
      expect(Yabeda.shoryuken.job_runtime.values).to include(
        { queue: 'sample_plain', worker: 'SamplePlainJob' } => kind_of(Numeric),
        { queue: 'failing_plain', worker: 'FailingPlainJob' } => kind_of(Numeric),
      )
    end
  end

  describe '#yabeda_tags worker method' do
    it 'uses custom labels for both shoryuken and application metrics' do
      Yabeda.shoryuken.jobs_executed_total.values.clear   # This is a hack
      Yabeda.shoryuken.job_runtime.values.clear           # This is a hack also
      Yabeda.test.whatever.values.clear                 # And this

      begin
        SampleComplexJob.perform_async(sample_body)
      rescue Exception
        nil
      end

      expect(Yabeda.shoryuken.jobs_executed_total.values).to eq(
        { queue: 'sample_complex', worker: 'SampleComplexJob', implicit: true } => 1,
      )
      expect(Yabeda.shoryuken.job_runtime.values).to include(
        { queue: 'sample_complex', worker: 'SampleComplexJob', implicit: true } => kind_of(Numeric),
      )
      expect(Yabeda.test.whatever.values).to include(
        { explicit: true, implicit: true } => 1,
      )
    end
  end

  describe 'collection of Shoryuken statistics' do
    it 'measures maximum runtime of currently running jobs' do
      Yabeda.shoryuken.running_job_runtime.values.clear # This is a hack
      described_class.jobs_started_at.clear

      workers = []
      workers.push(Thread.new { SampleLongRunningJob.perform_async(sample_body) })
      sleep 0.013 # Ruby can sleep less than requested
      workers.push(Thread.new { SampleLongRunningJob.perform_async(sample_body) })

      Yabeda.collectors.each(&:call)
      expect(Yabeda.shoryuken.running_job_runtime.values).to include(
        { queue: 'sample_long_running', worker: 'SampleLongRunningJob' } => (be >= 0.010),
      )

      sleep 0.013 # Ruby can sleep less than requested
      begin
        FailingPlainJob.perform_async(sample_body)
      rescue Exception
        nil
      end
      Yabeda.collectors.each(&:call)

      expect(Yabeda.shoryuken.running_job_runtime.values).to include(
        { queue: 'sample_long_running', worker: 'SampleLongRunningJob' } => (be >= 0.020),
        { queue: 'failing_plain', worker: 'FailingPlainJob' } => 0,
      )

      # When all jobs are completed, metric should respond with zero
      workers.map(&:join)
      Yabeda.collectors.each(&:call)
      expect(Yabeda.shoryuken.running_job_runtime.values).to include(
        { queue: 'sample_long_running', worker: 'SampleLongRunningJob' } => 0,
        { queue: 'failing_plain', worker: 'FailingPlainJob' } => 0,
      )
    end
  end
end
