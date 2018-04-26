

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
  unless client.validate_signature(body, signature)
    error 400 do 'Bad Request' end
  end



  events = client.parse_events_from(body)
  events.each { |event|
    puts event['source']['userId']
    case event
    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Text
        #message = {
        #  type: 'text',
        #  text: event.message['text']
        #}
        #client.reply_message(event['replyToken'], message)
        message = {
          type: "image",
          originalContentUrl: "https://scontent-tpe1-1.cdninstagram.com/vp/331ba48e05a3dfe09a529e2c5c3ea0db/5B9C2CE1/t51.2885-15/e35/30591957_608972819462853_200879017753051136_n.jpg",
          previewImageUrl: "https://scontent-tpe1-1.cdninstagram.com/vp/331ba48e05a3dfe09a529e2c5c3ea0db/5B9C2CE1/t51.2885-15/e35/30591957_608972819462853_200879017753051136_n.jpg"
        }
        response = client.push_message(event['source']['userId'], message)
        p response
      when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
        response = client.get_message_content(event.message['id'])
        tf = Tempfile.open("content")
        tf.write(response.body)
      end
    end
  }

  
  
  
  #
  #

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
