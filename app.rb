# frozen_string_literal: true

require './environment'
require 'sinatra'

class App < Sinatra::Base
  CSV_PATH = ENV.fetch('GH_CSV_NAME', 'members.csv')

  get '/' do
    content_type :html
    org = ENV.fetch('GH_ORGANIZATION')
    repo = ENV.fetch('GH_REPOSITORY')
    team = ENV.fetch('GH_TEAM')
    @search = ENV.fetch('GH_REPOSITORY_SEARCH')
    @team_url = "https://github.com/orgs/#{org}/teams/#{team}"
    csv_content = CSV.read(CSV_PATH, headers: true)
    @total_count = csv_content.size
    @removed_count = csv_content.select { |row| row['Removed'] == 'Yes' }.count

    if params['validated'] == 'true'
      csv_content = csv_content.select { |row| row['Access Validated'] == 'Yes' }
    elsif params['validated'] == 'false'
      csv_content = csv_content.reject { |row| row['Access Validated'] == 'Yes' }
    end

    if params['removed'] == 'true'
      csv_content = csv_content.select { |row| row['Removed'] == 'Yes' }
    elsif params['removed'] == 'false'
      csv_content = csv_content.reject { |row| row['Removed'] == 'Yes' }
    end

    csv_content = csv_content.select { |row| row['GitHub Login'] =~ /#{params['user']}/i } if params['user']
    csv_content = csv_content.select { |row| row['Issue Numbers'] =~ /#{params['issue']}/ } if params['issue']
    csv_content = csv_content.select { |row| row['Comments'] =~ /#{params['comment']}/i } if params['comment']

    erb :index, locals: { csv_content: csv_content, org: org, repo: repo }
  end

  post '/update' do
    content_type :json
    data = JSON.parse(request.body.read)
    csv_content = CSV.read(CSV_PATH, headers: true)

    csv_content.each do |row|
      row[data['field']] = data['value'] if row['GitHub Login'] == data['login']
    end

    # Backup the current CSV file before writing to it
    backup_path = "#{CSV_PATH}-#{Time.now.utc.iso8601}"
    FileUtils.cp(CSV_PATH, backup_path)

    # Remove old backups, keeping only the last 10
    backups = Dir.glob("#{CSV_PATH}-*").sort_by { |f| File.mtime(f) }
    FileUtils.rm(backups[0...-10]) if backups.size > 10

    CSV.open(CSV_PATH, 'w', write_headers: true, headers: csv_content.headers) do |csv|
      csv_content.each do |row|
        csv << row
      end
    end

    { status: 'success' }.to_json
  end

  helpers do
    def format_date(date_str)
      return '-' if date_str.nil? || date_str.empty?

      dates = date_str.split(', ').map { |date| Date.parse(date) }
      latest_date = dates.max
      latest_date.strftime('%B %d, %Y')
    end

    def issue_links(issue_numbers, org, repo)
      issue_numbers.split(', ').map do |issue_number|
        "<a href=\"https://github.com/#{org}/#{repo}/issues/#{issue_number}\" "\
        "class=\"text-blue-800 hover:underline\" target=\"_blank\">#{issue_number}</a>"
      end.join('<br>')
    end
  end
end
