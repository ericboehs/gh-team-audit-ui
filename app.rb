require 'sinatra'
require 'csv'
require 'date'
require 'json'
require 'pry'

get '/' do
  content_type :html
  csv_content = CSV.read('members.csv', headers: true)
  org = params[:org] || 'department-of-veterans-affairs'
  repo = params[:repo] || 'va.gov-team'
  erb :index, locals: { csv_content: csv_content, org: org, repo: repo }
end

post '/update' do
  content_type :json
  data = JSON.parse(request.body.read)
  csv_content = CSV.read('members.csv', headers: true)

  csv_content.each do |row|
    if row['GitHub Login'] == data['login']
      row[data['field']] = data['value']
    end
  end

  CSV.open('members.csv', 'w', write_headers: true, headers: csv_content.headers) do |csv|
    csv_content.each do |row|
      csv << row
    end
  end

  { status: 'success' }.to_json
end

helpers do
  def format_date(date_str)
    return "" if date_str.nil? || date_str.empty?

    dates = date_str.split(', ').map { |date| Date.parse(date) }
    latest_date = dates.max
    latest_date.strftime("%B %d, %Y")
  end

  def issue_links(issue_numbers, org, repo)
    issue_numbers.split(', ').map do |issue_number|
      "<a href=\"https://github.com/#{org}/#{repo}/issues/#{issue_number}\" class=\"text-blue-500 hover:underline\" target=\"_blank\">#{issue_number}</a>"
    end.join("<br>")
  end
end
