require 'rails_helper'

RSpec.describe GithubFetcher do
  context '::fetch' do
    it "Fetches and stores Github organizations' members and their events" do
      old_fetcher = GithubFetcher.create!(last_fetched_at: Time.now)

      GithubFetcher.fetch(
        organization: 'hashrocket',
        team: 'Employees'
      )

      new_fetcher = GithubFetcher.fetcher

      expect(new_fetcher.last_fetched_at).to_not(
        eq old_fetcher.last_fetched_at
      )
      expect(Developer.count).to_not eq 0
      expect(DeveloperActivity.count).to_not eq 0
    end
  end
end
