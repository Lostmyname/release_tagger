require "release_tagger/version"
require_relative "release_tagger/repo"
require 'pathname'

module ReleaseTagger

  Version = Struct.new(:major, :minor, :patch) do
    def bump(type)
      raise ArgumentError,
        "Could not bump #{type} version" unless respond_to?(type)

      numbers =
        case type
        when "major" then [major + 1, 0,         0]
        when "minor" then [major,     minor + 1, 0]
        when "patch" then [major,     minor,     patch + 1]
        end

      self.class.new(*numbers)
    end

    def to_s
      [major, minor, patch].join(".")
    end
  end

  class << self

    TAG_PRODUCTION = '-prod'
    TAG_QA         = '-qa'

    def color_terminal?
      ENV["TERM"] =~ /color/
    end

    def green(string)
      if color_terminal?
        "\x1b[0;32m#{string}\x1b[0m"
      else
        string
      end
    end

    def red(string)
      if color_terminal?
        "\x1b[0;31m#{string}\x1b[0m"
      else
        string
      end
    end

    def log(message)
      $stdout.puts(green(message))
    end

    def err(message)
      $stderr.puts(red(message))
    end

    def usage
      puts "Usage: #{File.basename($0)} (major|minor|patch)"
    end

    def valid_release_type?(type)
      %w{ major minor patch }.include?(type)
    end

    def on_master_branch?
      `git rev-parse --abbrev-ref HEAD`.strip == "master"
    end

    def behind_origin?
      %x{git fetch origin >/dev/null 2>&1; git diff --stat HEAD...@{u}}.strip != ""
    end

    def dirty_working_tree?
      %x{git status --porcelain 2>/dev/null | egrep "^(M| M)"}.strip != ""
    end

    def release_tag
      if on_master_branch?
        TAG_PRODUCTION
      else
        TAG_QA
      end
    end

    def release_message(version)
      "Release #{version}#{release_tag}"
    end

    def changelog
      # Get commits since latest tag if any (in this branch or from the original branched one)
      commits = ''
      previous_tag = %x{git describe --abbrev=0 --tags --match *.*.*}.strip
      unless $?.success?
        raise RuntimeError, "Error getting previous tag!"
      end
      unless previous_tag == ''
        commits = %x{git log --pretty="format:* %s" #{previous_tag}..HEAD}
        unless $?.success?
          raise RuntimeError, "Error getting changelog!"
        end
      end
      commits
    end

    def get_repo_name
      repo_name = %x{basename `git rev-parse --show-toplevel`}.strip
      unless $?.success?
        raise RuntimeError, "Error getting repo name!"
      end
      repo_name
    end

    def get_api_token
      home_config_file = Pathname.new(File.join(File.expand_path('~'), '.release_tagger', 'config'))
      etc_config_file = Pathname.new(File.join('/etc', 'release_tagger', 'config'))

      if etc_config_file.exist?
        package_cloud_api_token = etc_config_file.read.strip
      elsif home_config_file.exist?
        package_cloud_api_token = home_config_file.read.strip
      elsif ENV['PACKAGECLOUD_API_TOKEN']
        package_cloud_api_token = ENV['PACKAGECLOUD_API_TOKEN']
      else
        err %(Config for packagecloud not found!
Consider setting your packagecloud api token in any of:
  - #{home_config_file}
  - #{etc_config_file}
  - env var PACKAGECLOUD_API_TOKEN
)
        exit 1
      end

      package_cloud_api_token
    end

    def run!
      if ARGV.length != 1
        usage
        exit 1
      end

      release_type = ARGV.first

      unless valid_release_type?(release_type)
        usage
        exit 1
      end

      if behind_origin?
        err "You are behind the origin/master branch - please pull before releasing."
        exit 1
      end

      if dirty_working_tree?
        err "There are uncommitted changes in the working directory."
        err "Please commit or stash all changes before making a release."
        exit 1
      end

      package_name       = 'lmn-' + get_repo_name
      old_version_string = Repo.new().get_max_package_version(package_name, get_api_token)
      old_version_parts  = old_version_string.split(".").map(&:to_i)
      old_version        = Version.new(*old_version_parts)
      new_version        = old_version.bump(release_type)

      $stderr.write "This will release version #{new_version}. Are you sure? [y/N]: "
      unless STDIN.gets.strip == "y"
        err "Exiting."
        exit 1
      end

      log "Creating release commit"
      commit_output = %x{git add -u . && git commit -m "#{release_message}" 2>&1}
      unless $?.success?
        err "Error committing VERSION update:"
        err commit_output
        exit 1
      end

      log "Adding release tag"
      tag_output = %x{git tag #{new_version}#{release_tag} 2>&1}
      unless $?.success?
        err "Error adding version tag #{new_version}#{release_tag}:"
        err tag_output
        exit 1
      end

      log "Pushing release to origin"
      # Separate `push` and `push --tags` here, because only relatively recent
      # versions of git push both refs and tags with the single command.
      push_output = %x{git push 2>&1 && git push --tags 2>&1}
      unless $?.success?
        err "Error pushing release tag to origin:"
        err push_output
        exit 1
      end
    end
  end
end

ReleaseTagger.run!
