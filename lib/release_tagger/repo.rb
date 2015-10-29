require 'net/http'
require 'json'
require 'pathname'

module ReleaseTagger
  class Repo
    PACKAGECLOUD_ACCOUNT = 'lostmyname'
    REPO = 'qa'
    ITEMS_PER_PAGE = 1000
    ARCHS = %w(noarch x86_64)
    VERSIONS_URL = "https://packagecloud.io/api/v1/repos/#{PACKAGECLOUD_ACCOUNT}/#{REPO}/package/rpm/el/7/%s/%s/versions.json?per_page=#{ITEMS_PER_PAGE}"

    def get_api_token
      home_config_file = Pathname.new(File.join(File.expand_path('~'), '.release_tagger', 'packagecloud_token'))
      etc_config_file = Pathname.new(File.join('/etc', 'release_tagger', 'packagecloud_token'))

      if etc_config_file.exist?
        package_cloud_api_token = etc_config_file.read.strip
      elsif home_config_file.exist?
        package_cloud_api_token = home_config_file.read.strip
      elsif ENV['PACKAGECLOUD_API_TOKEN']
        package_cloud_api_token = ENV['PACKAGECLOUD_API_TOKEN']
      else
        puts %(Config for packagecloud not found!
Consider setting your packagecloud api token in any of:
  - #{home_config_file}
  - #{etc_config_file}
  - env var PACKAGECLOUD_API_TOKEN
)
        exit 1
      end

      package_cloud_api_token
    end

    def get_json_response(url)
      pc_api_token = get_api_token
      uri = URI.parse(url)
      req = Net::HTTP::Get.new(uri)
      req.basic_auth pc_api_token, ''
      response = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') {|http| http.request(req)}
      unless response.is_a?(Net::HTTPOK)
        puts "Error trying to get latest version of package #{package_name}"
        puts response.code
        exit 1
      end

      res = JSON.parse(response.body)
      res

    end

    def get_max_package_version(package_name)
      release_version = '0.0.0'
      ARCHS.each do |arch|
        res = get_json_response(VERSIONS_URL % [package_name, arch])
        unless res == []
          latest_package = res.select { |package| package['name'] == package_name}.max_by{ |package| package['version']}
          if Gem::Version.new(latest_package['version']) > Gem::Version.new(release_version)
            release_version = latest_package['version']
          end
        end
      end
      release_version
    end
  end
end


