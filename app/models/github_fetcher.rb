class GithubFetcher < ActiveRecord::Base
  # Silences postgres errors during seed
  validates_uniqueness_of :id

  def self.fetcher
    self.first
  end

  def self.fetch(organization='hashrocket', team_name='Employees')
    client = Octokit::Client.new
    team = client.get(
      "/orgs/#{organization}/teams"
    ).select{|t| t.name =~ /#{team_name}/i}.first

    members = client.get(
      "/teams/#{team.id}/members",
      per_page: 100 # max page size
    )

    while client.last_response.rels[:next] do
      api_href = client.last_response.rels[:next].href
      members += client.get(api_href)
    end

    developers = Developer.create_with_json_array(members.as_json)
    developers.each do |developer|
      activities = client.get("/users/#{developer.name}/events")
      DeveloperActivity.create_with_json(activities.as_json)
    end

    fetcher.update_attributes(last_fetched_at: Time.now)

    requests_notice = "#{client.rate_limit.remaining} github requests remaining"
    puts requests_notice
    requests_notice
  end

  def should_fetch?
    client = Octokit::Client.new
    fetcher = GithubFetcher.fetcher
    fetch_sleep = ENV['FETCH_SLEEP_DURATION'].to_i

    client.rate_limit.remaining > 0 &&
    (
      fetcher.last_fetched_at < fetch_sleep.seconds.ago ||
      Developer.all.empty?
    )
  end
end

#------------------------------------------------------------------------------
# GithubFetcher
#
# Name            SQL Type             Null    Default Primary
# --------------- -------------------- ------- ------- -------
# id              integer              false   1       true
# last_fetched_at timestamp with time zone false           false
#
#------------------------------------------------------------------------------
