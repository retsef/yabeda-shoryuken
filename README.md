# Yabeda::Shoryuken

[![Gem Version](https://badge.fury.io/rb/yabeda-shoryuken.svg)](https://rubygems.org/gems/yabeda-cloudwatch)

Yabeda plugin for easy [Shoryuken] gem collect metrics from your application

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'yabeda-shoryuken'
```

And then execute:

    $ bundle

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