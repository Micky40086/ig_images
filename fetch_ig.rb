

require 'sinatra'

get '/' do
  erb :index
end

post '/get_images' do
  require 'nokogiri'
  require 'open-uri'
  require 'json'
  
  doc = Nokogiri::HTML(open(params[:ig_url]))
  temp_array = []
  temp_str = doc.xpath("//script")[2].text
  temp_str.slice! "window._sharedData = "
  temp_str = temp_str[0,temp_str.length-1]
  JSON.parse(temp_str)['entry_data']['PostPage'][0]['graphql']['shortcode_media']['edge_sidecar_to_children']['edges'].each_with_index do |hehe,index|
    temp_array.push(hehe['node']['display_url'])
    #open("#{index}.png", 'wb') do |file|
    #    file << open(hehe['node']['display_url']).read
    #end
  end
  #'https://www.instagram.com/p/BhYoWOVA5sg/'
  status 200
  return temp_array.to_json
end