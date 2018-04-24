

require 'sinatra'
require 'nokogiri'
require 'open-uri'
require 'json'

get '/' do
  erb :index
end

post '/get_images' do

  doc = Nokogiri::HTML(open(params[:ig_url]))
  temp_array = []
  
  temp_str = doc.xpath("//script")[2].text
  temp_str.slice! "window._sharedData = "
  temp_str = temp_str[0,temp_str.length-1]

  fetch_data = JSON.parse(temp_str)['entry_data']['PostPage'][0]['graphql']['shortcode_media']
  if fetch_data['edge_sidecar_to_children']
    fetch_data['edge_sidecar_to_children']['edges'].each_with_index do |hehe,index|
      temp_array.push(hehe['node']['display_url'])
    end
  else 
    temp_array.push(fetch_data['display_url'])
  end

  status 200
  return temp_array.to_json
  
end