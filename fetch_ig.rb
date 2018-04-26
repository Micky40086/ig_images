

require 'sinatra'
require 'nokogiri'
require 'open-uri'
require 'json'
require 'rufus-scheduler'
require 'line/bot'

get '/' do
  erb :index
  puts params
end

post '/' do
  body = request.body.read

  signature = request.env['HTTP_X_LINE_SIGNATURE']
  puts signature
  puts ENV["LINE_CHANNEL_TOKEN"]
  unless client.validate_signature(body, signature)
    error 400 do 'Bad Request' end
  end

  message = {
    type: 'text',
    text: 'hello'
  }
  
  response = client.push_message("<to>", message)
  p response

  "OK"
end

post '/get_images' do

  doc = Nokogiri::HTML(open(params[:ig_url]))
  temp_array = []
  
  temp_str = doc.xpath("//script")[2].text
  temp_str.slice! "window._sharedData = "
  temp_str = temp_str[0,temp_str.length-1]

  fetch_data = JSON.parse(temp_str)['entry_data']['PostPage'][0]['graphql']['shortcode_media']
  if fetch_data['edge_sidecar_to_children']
    fetch_data['edge_sidecar_to_children']['edges'].each do |item|
      temp_array.push({ 
        image_url: item['node']['display_url'],
        video_url: item['node']['video_url'],
        is_video: item['node']['is_video'] ? true : false
      })
    end
  else 
    temp_array.push({ 
      image_url: fetch_data['display_url'],
      video_url: fetch_data['video_url'],
      is_video: fetch_data['is_video'] ? true : false
    })
  end

  status 200
  content_type :json
  { result: temp_array }.to_json
end

get '/hehe' do
  current_time = Time.now.to_i
  temp_json = getInstagramJson("https://www.instagram.com/ahnhani_92/")
  temp_array = []
  posts = JSON.parse(temp_json)['entry_data']['ProfilePage'][0]['graphql']['user']['edge_owner_to_timeline_media']['edges']
  posts.each do |post|
    if current_time - post['node']['taken_at_timestamp'] <= 300
      puts "五分鐘內"
    else 
      break
    end
  end
end

def client
  @client ||= Line::Bot::Client.new { |config|
    config.channel_secret = "6452fb1e7907ebd9dd27200fb4fdacba"
    config.channel_token = "odWztlhkQQk012eRT8z/o8xGcyO1U9M4+mf/a5DAOld3tT3eOzuOT1oF8dnD0LVXazC+yeCPbcyXhXuXauqwKqobqPjWPrwB0n51k8jKNDR1cUhl4ixu9RuYuMkX164fipeVsTDhSPMcEmxv638yVgdB04t89/1O/w1cDnyilFU="
  }
end

def getInstagramJson(url)
  doc = Nokogiri::HTML(open(url))
  temp_json = doc.xpath("//script")[2].text
  temp_json.slice! "window._sharedData = "
  temp_json = temp_json[0,temp_json.length-1]
  return temp_json
end

#scheduler = Rufus::Scheduler.new
#scheduler.every '30s' do
#  puts "change the oil filter!"
#end
