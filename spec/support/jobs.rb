# frozen_string_literal: true

class DefaultJob
  include Shoryuken::Worker
  shoryuken_options queue: 'default'

  def perform(*_args)
    'My default job'
  end
end

class SamplePlainJob
  include Shoryuken::Worker
  shoryuken_options queue: 'sample_plain'

  def perform(*_args)
    'My job is simple'
  end
end

class SampleLongRunningJob
  include Shoryuken::Worker
  shoryuken_options queue: 'sample_long_running'

  def perform(*_args)
    sleep 0.05
    'Phew, I\'m done!'
  end
end

class SampleComplexJob
  include Shoryuken::Worker
  shoryuken_options queue: 'sample_complex'

  def perform(*_args)
    Yabeda.test.whatever.increment({ explicit: true })
    'My job is complex'
  end

  def yabeda_tags
    { implicit: true }
  end
end

class FailingPlainJob
  include Shoryuken::Worker
  shoryuken_options queue: 'failing_plain'

  def perform(*_args)
    raise 'Badaboom'
  end
end

