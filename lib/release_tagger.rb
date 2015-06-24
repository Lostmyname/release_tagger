require "release_tagger/version"
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

    def release_message(version)
      "Release v#{version}"
    end

    def changelog(old_version)
      commits = %x{git log --pretty="format:* %s" v#{old_version}..HEAD}
      unless $?.success?
        raise RuntimeError, "Error getting changelog!"
      end
      commits
    end

    def run!
      if ARGV.length != 1
        usage
        exit 1
      end

      release_type = ARGV.first

      if !valid_release_type?(release_type)
        usage
        exit 1
      end

      if !on_master_branch?
        err "You must be on the master branch to make a release"
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

      version_file = Pathname.new(__FILE__).join("..", "..", "VERSION")

      if !version_file.exist?
        err "Could not find VERSION file - this must be present to make a release"
        exit 1
      end

      old_version_string = version_file.read.strip
      old_version_parts  = old_version_string.split(".").map(&:to_i)
      old_version        = Version.new(*old_version_parts)
      new_version        = old_version.bump(release_type)

      $stderr.write "This will release version #{new_version}. Are you sure? [y/N]: "
      unless STDIN.gets.strip == "y"
        err "Exiting."
        exit 1
      end

      if !version_file.writable?
        err "Could not write to VERSION file - please check you have write permissions"
        exit 1
      end

      log "Updating VERSION file to #{new_version}"
      version_file.open("w") do |f|
        f.write(new_version.to_s)
      end

      log "Creating release commit"
      commits = changelog(old_version)
      commit_output = %x{git add -u . && git commit -m "#{release_message(new_version)}\n\n#{commits}" 2>&1}
      unless $?.success?
        err "Error committing VERSION update:"
        err commit_output
        exit 1
      end

      log "Adding release tag"
      tag_output = %x{git tag v#{new_version} 2>&1}
      unless $?.success?
        err "Error adding version tag v#{new_version}:"
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
