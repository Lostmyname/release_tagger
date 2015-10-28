# ReleaseTagger

A simple command-line tool to manage a git tag-based release workflow.
It:

1. Ensures the working directory is clean and up-to-date
2. Bumps the requested version number (major, minor or patch)
3. Creates an annotated tag noting changes since the last release
4. Pushes the tag to the origin repo

The actual version of the software will be retrieved from our package repository in the cloud
(packagecloud)
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

## Configuration
The only required configuration is the packagecloud API key to retrieve the latest version.
You can configure it adding the API key (ask the infra/geoff squad for it) at:
- /etc/release_tagger/packagecloud_token
- ~/.release_tagger/packagecloud_token
- as an environment variable, PACKAGECLOUD_API_TOKEN

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
https://github.com/Lostmyname/release_tagger. This project is intended
to be a safe, welcoming space for collaboration, and contributors are
expected to adhere to the [Contributor
Covenant](contributor-covenant.org) code of conduct.
