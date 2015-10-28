require 'net/http'
require 'json'
require 'pathname'

module ReleaseTagger
  class Repo
    PACKAGECLOUD_ACCOUNT = 'lostmyname'
    REPO = 'qa'
    ITEMS_PER_PAGE = 1000
    VERSIONS_URL = "https://packagecloud.io/api/v1/repos/#{PACKAGECLOUD_ACCOUNT}/#{REPO}/package/rpm/el/7/%s/x86_64/versions.json?per_page=#{ITEMS_PER_PAGE}"

    def get_max_package_version(package_name, pc_api_token)
      uri = URI.parse(VERSIONS_URL % package_name)
      req = Net::HTTP::Get.new(uri)
      req.basic_auth pc_api_token, ''
      response = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') {|http| http.request(req)}

      unless response.is_a?(Net::HTTPOK)
        puts "Error trying to get latest version of package #{package_name}"
        puts response.code
        exit 1
      end

      res = JSON.parse(response.body)
      release_version = '1.0.0'
      if res == []
        $stderr.write %(Unable to find the latest version of the package in packagecloud.
This will create a tagged commit for #{initial_release_version}.
Are you sure? [y/N])
        unless STDIN.gets.strip == "y"
          exit 1
        end
      else
        latest_package = res.select { |package| package['name'] == package_name}.max_by{ |package| package['version']}
        release_version = latest_package['version']
      end
      release_version
    end
  end
end


