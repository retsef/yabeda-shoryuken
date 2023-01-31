# Yabeda::Shoryuken

[![Gem Version](https://badge.fury.io/rb/yabeda-shoryuken.svg)](https://rubygems.org/gems/yabeda-shoryuken)

Yabeda plugin for easy [Shoryuken] gem collect metrics from your application

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'yabeda-shoryuken'
# Then add monitoring system adapter, e.g.:
# gem 'yabeda-cloudwatch'
```

And then execute:

    $ bundle

If you're not on Rails then configure Yabeda after your application was initialized:

```ruby
Yabeda.configure!
```

_If you're using Ruby on Rails then Yabeda will configure itself automatically!_

**And that is it!** Shoryuken metrics are being collected!

## Metrics

### Local per-process metrics

Metrics representing state of current Shoryuken worker process and stats of executed or executing jobs:

- Total number of executed jobs: `shoryuken_jobs_executed_total` -  (segmented by queue and class name)
- Number of jobs have been finished successfully: `shoryuken_jobs_success_total` (segmented by queue and class name)
- Number of jobs have been failed: `shoryuken_jobs_failed_total` (segmented by queue and class name)
- Time of job run: `shoryuken_job_runtime` (seconds per job execution, segmented by queue and class name)
- Maximum runtime of currently executing jobs: `shoryuken_running_job_runtime` (useful for detection of hung jobs, segmented by queue and class name)

### Client metrics

Metrics collected where jobs are being pushed to queues (everywhere):

- Total number of enqueued messages: `shoryuken_messages_enqueued_total_count` (segmented by `queue`)

## Custom tags

You can add additional tags to these metrics by declaring `yabeda_tags` method in your worker.

```ruby
# This block is optional but some adapters (like Prometheus) requires that all tags should be declared in advance
Yabeda.configure do
  default_tag :importance, nil
end
class MyWorker
  include Shoryuken::Worker
  def yabeda_tags(*params) # This method will be called first, before +perform+
    { importance: extract_importance(params) }
  end
  def perform(*params)
    # Your logic here
  end
end
```
## Configuration
Configuration is handled by [anyway_config] gem. With it you can load settings from environment variables (upcased and prefixed with `YABEDA_SIDEKIQ_`), YAML files, and other sources. See [anyway_config] docs for details.
Config key                | Type     | Default                                                 | Description                                                                                                                                        |
------------------------- | -------- | ------------------------------------------------------- |----------------------------------------------------------------------------------------------------------------------------------------------------|
`collect_cluster_metrics` | boolean  | Enabled in Shoryuken worker processes, disabled otherwise | Defines whether this Ruby process should collect and expose metrics representing state of the whole Shoryuken installation (queues, processes, etc). |
`declare_process_metrics` | boolean  | Enabled in Shoryuken worker processes, disabled otherwise | Declare metrics that are only tracked inside worker process even outside of them. Useful for multiprocess metric collection.                       |


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yabeda-rb/yabeda-shoryuken.

### Releasing

1. Bump version number in `lib/yabeda/shoryuken/version.rb`

   In case of pre-releases keep in mind [rubygems/rubygems#3086](https://github.com/rubygems/rubygems/issues/3086) and check version with command like `Gem::Version.new(Yabeda::Shoryuken::VERSION).to_s`

2. Fill `CHANGELOG.md` with missing changes, add header with version and date.

3. Make a commit:

   ```sh
   git add lib/yabeda/shoryuken/version.rb CHANGELOG.md
   version=$(ruby -r ./lib/yabeda/shoryuken/version.rb -e "puts Gem::Version.new(Yabeda::Shoryuken::VERSION)")
   git commit --message="${version}: " --edit
   ```

4. Create annotated tag:

   ```sh
   git tag v${version} --annotate --message="${version}: " --edit --sign
   ```

5. Fill version name into subject line and (optionally) some description (list of changes will be taken from changelog and appended automatically)

6. Push it:

   ```sh
   git push --follow-tags
   ```

7. GitHub Actions will create a new release, build and push gem into RubyGems! You're done!

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

[Shoryuken]: https://github.com/ruby-shoryuken/shoryuken "A super efficient Amazon SQS thread based message processor for Ruby"
[yabeda]: https://github.com/yabeda-rb/yabeda
[yabeda-prometheus]: https://github.com/yabeda-rb/yabeda-prometheus
[anyway_config]: https://github.com/palkan/anyway_config "Configuration library for Ruby gems and applications"