# ReleaseTagger

A simple command-line tool to manage a git tag-based release workflow.
It:

1. Ensures the working directory is clean and up-to-date
2. Ensures a non-master branch is not being released
3. Bumps the requested version number (major, minor or patch)
4. Creates a release commit noting changes since the last release
5. Tags the release commit
6. Pushes the whole lot to the origin repo

That's all. Any other build steps are to be managed manually, or by CI
watching for release tags in the origin repo.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'release_tagger'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install release_tagger

## Usage

    $ do_release (major|minor|patch)

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `rake rspec` to run the tests. You can also run `bin/console`
for an interactive prompt that will allow you to experiment. Run `bundle
exec release_tagger` to use the gem in this directory, ignoring other
installed copies of this gem.

To install this gem onto your local machine, run `bundle exec rake
install`.

To release a new version, use the gem itself to apply the version tag,
then manually:

    $ gem build release_tagger.gemspec
    $ gem push

This will be handled by CI when this has tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/[USERNAME]/release_tagger. This project is intended
to be a safe, welcoming space for collaboration, and contributors are
expected to adhere to the [Contributor
Covenant](contributor-covenant.org) code of conduct.
