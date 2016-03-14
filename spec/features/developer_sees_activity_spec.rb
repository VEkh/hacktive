require 'rails_helper'

RSpec.feature "Hacker list" do
  include ActiveJob::TestHelper

  before do
    event_types = [
      'IssuesEvent',
      'PullRequestEvent',
      'PushEvent',
      'WatchEvent'
    ]

    event_types.each do |event_type|
      EventType.find_or_create_by(name: event_type)
    end

    @fetcher = GithubFetcher.create!(
      id: 1,
      last_fetched_at: Time.now
    )
  end

  scenario "Developer with most recent github activity is at top of list", type: :request do
    # https://api.github.com/users/vekh/events
    vekh_events = [
      {
        "id" => "3650080452",
        "type" => "PushEvent",
        "actor" => {
          "id" => 735821,
          "login" => "VEkh",
          "gravatar_id" => "",
          "url" => "https://api.github.com/users/VEkh",
          "avatar_url" => "https://avatars.githubusercontent.com/u/735821?"
        },
        "repo" => {
          "id" => 51382870,
          "name" => "VEkh/sideprojects",
          "url" => "https://api.github.com/repos/VEkh/sideprojects"
        },
        "payload" => {
          "push_id" => 979550639,
          "size" => 1,
          "distinct_size" => 1,
          "ref" => "refs/heads/master",
          "head" => "30cbf09da0778e4f1eb0bc94575d858d68ea95d6",
          "before" => "6ae4312e0b28cd32d3b49e11ecae68bbe9b58d62",
          "commits" => [
            {
              "sha" => "30cbf09da0778e4f1eb0bc94575d858d68ea95d6",
              "author" => {
                "email" => "vekechukwu@gmail.com",
                "name" => "Vidal Ekechukwu"
              },
              "message" => "Migrating to Hashrocket git",
              "distinct" => true,
              "url" => "https://api.github.com/repos/VEkh/sideprojects/commits/30cbf09da0778e4f1eb0bc94575d858d68ea95d6"
            }
          ]
        },
        "public" => true,
        "created_at" => Time.now.to_s
      }
    ]

    vekh = vekh_events.first['actor']

    Developer.create_with_json(vekh)
    DeveloperActivity.create_with_json(vekh_events)

    # https://api.github.com/users/chriserin/events
    chriserin_events = [
      {
        "id" => "3613641536",
        "type" => "PushEvent",
        "actor" => {
          "id" => 597909,
          "login" => "chriserin",
          "gravatar_id" => "",
          "url" => "https://api.github.com/users/chriserin",
          "avatar_url" => "https://avatars.githubusercontent.com/u/597909?"
        },
        "repo" => {
          "id" => 31873570,
          "name" => "chriserin/seq27",
          "url" => "https://api.github.com/repos/chriserin/seq27"
        },
        "payload" => {
          "push_id" => 966181213,
          "size" => 1,
          "distinct_size" => 1,
          "ref" => "refs/heads/master",
          "head" => "1007f813c367db8a610ea7a515ee25fb90bc498f",
          "before" => "57779ce19b72f5c4ea4146e98e0d73efbf9bdcc1",
          "commits" => [
            {
              "sha" => "1007f813c367db8a610ea7a515ee25fb90bc498f",
              "author" => {
                "email" => "dev@hashrocket.com",
                "name" => "Hashrocket Workstation"
              },
              "message" => "Upgrade rails -> 4.2.5:W",
              "distinct" => true,
              "url" => "https://api.github.com/repos/chriserin/seq27/commits/1007f813c367db8a610ea7a515ee25fb90bc498f"
            }
          ]
        },
        "public" => true,
        "created_at" => 1.hour.ago.to_s
      }
    ]

    chriserin = chriserin_events.first['actor']

    Developer.create_with_json(chriserin)
    DeveloperActivity.create_with_json(chriserin_events)

    get '/developers.json'
    developers = JSON.parse(response.body)

    expect(developers.first['name']).to eq 'VEkh'
  end

  scenario "Developer sees commit to github project", type: :request do
    # https://api.github.com/users/vekh
    github_developer = {
      "id" => 735821,
      "login" => "VEkh"
    }

    # https://api.github.com/users/vekh/events
    github_developer_events = [
      {
        "id" => "3650080452",
        "type" => "PushEvent",
        "actor" => {
          "id" => 735821,
          "login" => "VEkh",
          "gravatar_id" => "",
          "url" => "https://api.github.com/users/VEkh",
          "avatar_url" => "https://avatars.githubusercontent.com/u/735821?"
        },
        "repo" => {
          "id" => 51382870,
          "name" => "VEkh/sideprojects",
          "url" => "https://api.github.com/repos/VEkh/sideprojects"
        },
        "payload" => {
          "push_id" => 979550639,
          "size" => 1,
          "distinct_size" => 1,
          "ref" => "refs/heads/master",
          "head" => "30cbf09da0778e4f1eb0bc94575d858d68ea95d6",
          "before" => "6ae4312e0b28cd32d3b49e11ecae68bbe9b58d62",
          "commits" => [
            {
              "sha" => "30cbf09da0778e4f1eb0bc94575d858d68ea95d6",
              "author" => {
                "email" => "vekechukwu@gmail.com",
                "name" => "Vidal Ekechukwu"
              },
              "message" => "Migrating to Hashrocket git",
              "distinct" => true,
              "url" => "https://api.github.com/repos/VEkh/sideprojects/commits/30cbf09da0778e4f1eb0bc94575d858d68ea95d6"
            }
          ]
        },
        "public" => true,
        "created_at" => Time.now.to_s
      }
    ]

    Developer.create_with_json(github_developer)
    DeveloperActivity.create_with_json(github_developer_events)

    get '/developers.json'
    top_developer = JSON.parse(response.body).first
    most_recent_activity = top_developer['activities'].first

    expect(top_developer['name']).to eq 'VEkh'
    expect(most_recent_activity['repo_name']).to eq 'VEkh/sideprojects'
    expect(most_recent_activity['payload'].values).to include 'Migrating to Hashrocket git'
  end

  scenario "Developer sees issue action on github project", type: :request do
    # https://api.github.com/users/chriserin
    github_developer = {
      "id" => 597909,
      "login" => "chriserin"
    }

    # https://api.github.com/users/chriserin/events
    github_developer_events = [
      {
        "id" => "3641309227",
        "type" => "IssuesEvent",
        "actor" => {
          "id" => 597909,
          "login" => "chriserin",
          "gravatar_id" => "",
          "url" => "https://api.github.com/users/chriserin",
          "avatar_url" => "https://avatars.githubusercontent.com/u/597909?"
        },
        "repo" => {
          "id" => 31873570,
          "name" => "chriserin/seq27",
          "url" => "https://api.github.com/repos/chriserin/seq27"
        },
        "payload" => {
          "action" => "closed",
          "issue" => {
            "id" => 128439611
          }
        },
        "public" => true,
        "created_at" => Time.now.to_s
      }
    ]

    Developer.create_with_json(github_developer)
    DeveloperActivity.create_with_json(github_developer_events)

    get '/developers.json'
    top_developer = JSON.parse(response.body).first
    most_recent_activity = top_developer['activities'].first

    expect(top_developer['name']).to eq 'chriserin'
    expect(most_recent_activity['repo_name']).to eq 'chriserin/seq27'
    expect(most_recent_activity['payload']['128439611']).to eq 'closed'
  end

  scenario "Developer sees pull request to github project", type: :request do
    # https://api.github.com/users/chriserin
    github_developer = {
      "id" => 597909,
      "login" => "chriserin"
    }

    # https://api.github.com/users/chriserin/events
    github_developer_events = [
      {
        "id" => "3590105431",
        "type" => "PullRequestEvent",
        "actor" => {
          "id" => 597909,
          "login" => "chriserin",
          "gravatar_id" => "",
          "url" => "https://api.github.com/users/chriserin",
          "avatar_url" => "https://avatars.githubusercontent.com/u/597909?"
        },
        "repo" => {
          "id" => 50210172,
          "name" => "hashrocket/hr_hotels",
          "url" => "https://api.github.com/repos/hashrocket/hr_hotels"
        },
        "payload" => {
          "action" => "opened",
          "number" => 1,
          "pull_request" => {
            "id" => 57790579
          }
        },
        "public" => true,
        "created_at" => Time.now.to_s,
        "org" => {
          "id" => 5875,
          "login" => "hashrocket",
          "gravatar_id" => "",
          "url" => "https://api.github.com/orgs/hashrocket",
          "avatar_url" => "https://avatars.githubusercontent.com/u/5875?"
        }
      }
    ]

    Developer.create_with_json(github_developer)
    DeveloperActivity.create_with_json(github_developer_events)

    get '/developers.json'
    top_developer = JSON.parse(response.body).first
    most_recent_activity = top_developer['activities'].first

    expect(top_developer['name']).to eq 'chriserin'
    expect(most_recent_activity['repo_name']).to eq 'hashrocket/hr_hotels'
    expect(most_recent_activity['payload']['57790579']).to eq 'opened'
  end

  scenario "Developer sees star event on github project", type: :request do
    # https://api.github.com/users/chriserin
    github_developer = {
      "id" => 735821,
      "login" => "VEkh"
    }

    # https://api.github.com/users/chriserin/events
    github_developer_events = [
      {
        "id" => "3633890600",
        "type" => "WatchEvent",
        "actor" => {
          "id" => 735821,
          "login" => "VEkh",
          "gravatar_id" => "",
          "url" => "https://api.github.com/users/VEkh",
          "avatar_url" => "https://avatars.githubusercontent.com/u/735821?"
        },
        "repo" => {
          "id" => 30444489,
          "name" => "jbranchaud/til",
          "url" => "https://api.github.com/repos/jbranchaud/til"
        },
        "payload" => {
          "action" => "started"
        },
        "public" => true,
        "created_at" => Time.now.to_s
      }
    ]

    Developer.create_with_json(github_developer)
    DeveloperActivity.create_with_json(github_developer_events)

    get '/developers.json'
    top_developer = JSON.parse(response.body).first
    most_recent_activity = top_developer['activities'].first

    expect(top_developer['name']).to eq 'VEkh'
    expect(most_recent_activity['repo_name']).to eq 'jbranchaud/til'
    expect(most_recent_activity['payload']['action']).to eq 'started'
  end

  scenario 'Developer sees time description for a recent commit', type: :request do
    # https://api.github.com/users/vekh
    github_developer = {
      "id" => 735821,
      "login" => "VEkh"
    }

    # https://api.github.com/users/vekh/events
    event_occured_at = Time.now.to_s
    github_developer_events = [
      {
        "id" => "3650080452",
        "type" => "PushEvent",
        "actor" => {
          "id" => 735821,
          "login" => "VEkh",
          "gravatar_id" => "",
          "url" => "https://api.github.com/users/VEkh",
          "avatar_url" => "https://avatars.githubusercontent.com/u/735821?"
        },
        "repo" => {
          "id" => 51382870,
          "name" => "VEkh/sideprojects",
          "url" => "https://api.github.com/repos/VEkh/sideprojects"
        },
        "payload" => {
          "commits" => [
            {
              "sha" => "30cbf09da0778e4f1eb0bc94575d858d68ea95d6",
              "author" => {
                "email" => "vekechukwu@gmail.com",
                "name" => "Vidal Ekechukwu"
              },
              "message" => "Migrating to Hashrocket git",
              "distinct" => true,
              "url" => "https://api.github.com/repos/VEkh/sideprojects/commits/30cbf09da0778e4f1eb0bc94575d858d68ea95d6"
            }
          ]
        },
        "public" => true,
        "created_at" => event_occured_at
      }
    ]

    Developer.create_with_json(github_developer)
    DeveloperActivity.create_with_json(github_developer_events)

    get '/developers.json'
    top_developer = JSON.parse(response.body).first
    most_recent_activity = top_developer['activities'].first

    expect(top_developer['name']).to eq 'VEkh'
    expect(
      Time.parse(most_recent_activity['event_occurred_at'])
    ).to eq Time.parse(event_occured_at)
  end

  scenario 'Developer card not shown if activity occurred before cutoff date', type: :request do
    # https://api.github.com/users/vekh
    github_developer = {
      "id" => 735821,
      "login" => "VEkh"
    }

    # https://api.github.com/users/vekh/events
    pre_cutoff_date = (
      Time.now -
      ENV['ACTIVITY_CUTOFF_DURATION'].to_i.seconds -
      1.hour
    )

    github_developer_events = [
      {
        "id" => "3633736925",
        "type" => "PushEvent",
        "actor" => {
          "id" => 735821,
          "login" => "VEkh",
          "gravatar_id" => "",
          "url" => "https://api.github.com/users/VEkh",
          "avatar_url" => "https://avatars.githubusercontent.com/u/735821?"
        },
        "repo" => {
          "id" => 51382870,
          "name" => "VEkh/sideprojects",
          "url" => "https://api.github.com/repos/VEkh/sideprojects"
        },
        "payload" => {
          "commits" => [
            {
              "sha" => "6ae4312e0b28cd32d3b49e11ecae68bbe9b58d62",
              "author" => {
                "email" => "vekechukwu@gmail.com",
                "name" => "Vidal Ekechukwu"
              },
              "message" => "Javascripts are loaded. React flow is set up.",
              "distinct" => true,
              "url" => "https://api.github.com/repos/VEkh/sideprojects/commits/6ae4312e0b28cd32d3b49e11ecae68bbe9b58d62"
            }
          ]
        },
        "public" => true,
        "created_at" => pre_cutoff_date
      }
    ]

    Developer.create_with_json(github_developer)
    DeveloperActivity.create_with_json(github_developer_events)

    get '/developers.json'
    developers = JSON.parse(response.body)

    expect(developers).to be_empty
  end
end
