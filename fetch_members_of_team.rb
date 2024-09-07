require './environment'
require 'net/http'

GITHUB_TOKEN = ENV.fetch('GH_TOKEN')

class GitHubClient
  BASE_URL = 'https://api.github.com'

  def initialize(token)
    @token = token
  end

  def get(uri)
    uri = URI(uri)
    req = setup_request(uri)
    res = make_request(req)
    handle_rate_limit(res)

    case res
    when Net::HTTPSuccess
      {
        body: JSON.parse(res.body),
        headers: res.each_header.to_h
      }
    else
      puts "HTTP Request failed (#{res.code} #{res.message})"
      nil
    end
  end

  def search_issues(org, repo, query)
    uri = URI("#{BASE_URL}/search/issues?q=repo:#{org}/#{repo}+#{query}")
    paginated_get(uri) { |response| response[:body]['items'] }
  end

  def get_user_details(login)
    uri = URI("#{BASE_URL}/users/#{login}")
    get(uri)[:body]
  end

  def paginated_get(uri)
    items = []

    loop do
      response = get(uri)
      break unless response

      items.concat(yield(response))
      link_header = response[:headers]['link']
      break unless link_header&.include?('rel="next"')

      # Extract the next page URL from the Link header
      next_page_link = link_header.split(',').find { |link| link.include?('rel="next"') }
      uri = URI(next_page_link.match(/<(.*?)>/)[1])
    end

    items
  end

  private

  def setup_request(uri)
    req = Net::HTTP::Get.new(uri)
    req['Authorization'] = "Bearer #{@token}"
    req['Accept'] = 'application/vnd.github.v3+json'
    req
  end

  def make_request(req)
    Net::HTTP.start(req.uri.hostname, req.uri.port, use_ssl: true) do |http|
      http.request(req)
    end
  end

  def handle_rate_limit(response)
    remaining = response['x-ratelimit-remaining'].to_i
    reset_time = response['x-ratelimit-reset'].to_i
    limit = response['x-ratelimit-limit'].to_i

    return unless remaining < 10

    sleep_time = [reset_time - Time.now.to_i, 0].max
    puts "Rate limit almost exceeded, sleeping for #{sleep_time} seconds..."
    sleep(sleep_time)
  end
end

def fetch_team_members(client, org, team_slug)
  client.paginated_get("https://api.github.com/orgs/#{org}/teams/#{team_slug}/members") { |response| response[:body] }
end

def fetch_issues_for_member(client, org, repo, member_login, title)
  client.search_issues(org, repo, "is:issue in:body \"#{member_login}\" in:title \"#{title}\"")
end

org = ENV.fetch('GH_ORGANIZATION')
team_slug = ENV.fetch('GH_TEAM')
repo = ENV.fetch('GH_REPOSITORY')
search = ENV.fetch('GH_REPOSITORY_SEARCH')
search_except = ENV.fetch('GH_REPOSITORY_SEARCH_EXCEPT')

client = GitHubClient.new(GITHUB_TOKEN)
members = fetch_team_members(client, org, team_slug)

CSV.open(ENV.fetch('GH_CSV_NAME', 'members.csv'), 'w') do |csv|
  csv << [
    'GitHub Login',
    'Name',
    'Access Validated',
    'Removed',
    'Issue Numbers',
    'Created At',
    'Updated At',
    'Comments'
  ]

  members.each do |member|
    member_login = member['login']
    user_details = client.get_user_details(member_login)
    member_name = user_details['name'] || 'N/A'

    issues = fetch_issues_for_member(client, org, repo, member_login, search)
    issues = issues.reject { |issue| issue['title'].downcase.include?(search_except) } unless search_except.empty?

    issue_numbers = issues.map { |issue| issue['number'] }.join(', ')
    created_at = issues.map { |issue| issue['created_at'] }.join(', ')
    updated_at = issues.map { |issue| issue['updated_at'] }.join(', ')

    csv << [member_login, member_name, 'No', 'No', issue_numbers, created_at, updated_at, nil]
  end
end
