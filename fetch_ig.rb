

require 'sinatra'
require 'nokogiri'
require 'open-uri'
require 'json'
require 'rufus-scheduler'
require 'line/bot'
require './user'

get '/' do
  erb :index
end

post '/line_bot' do
  body = request.body.read
  puts body
  signature = request.env['HTTP_X_LINE_SIGNATURE']
  unless client.validate_signature(body, signature)
    error 400 do 'Bad Request' end
  end

  events = client.parse_events_from(body)
  events.each { |event|
    case event
    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Text
        user = source_user(event['source'])
        if event.message['type'] == 'text'
          
          reply_message = handle_message(user,event.message['text'])
          if reply_message.present?
            message = {
              type: 'text',
              text: reply_message
            }
            client.reply_message(event['replyToken'], message)
          end
        end
      when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
        #response = client.get_message_content(event.message['id'])
        #tf = Tempfile.open("content")
        #tf.write(response.body)
      end
    end
  }

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

get '/run_HEHE' do
  current_time = Time.now.to_i
  User.all.each do |user|
    user.ig_items.each do |item|
      begin
        latest_posts = []
        temp_json = getInstagramJson("https://www.instagram.com/#{item.account}/")
        posts = JSON.parse(temp_json)['entry_data']['ProfilePage'][0]['graphql']['user']['edge_owner_to_timeline_media']['edges']
        posts.each do |post|
          node = post['node']
          if current_time - node['taken_at_timestamp'] <= 300
            latest_posts.push(node['shortcode'])
          else 
            break
          end
        end

        latest_posts.each do |post_id|
          post_json = getInstagramJson("https://www.instagram.com/p/#{post_id}/")
          media = JSON.parse(post_json)['entry_data']['PostPage'][0]['graphql']['shortcode_media']
          if media['edge_sidecar_to_children']
            media['edge_sidecar_to_children']['edges'].each do |item|
              item['node']['is_video'] ? message = video_template(item['node']['video_url'], item['node']['display_url']) : message = image_template(item['node']['display_url'])
              client.push_message(user.source_id, message)
            end
          else 
            media['is_video'] ? message = video_template(media['video_url'], media['display_url']) : message = image_template(media['display_url'])
            client.push_message(user.source_id, message)
          end
        end
      rescue
        puts "hehehe ERROR"
      end
    end
  end

  status 200
  content_type :json
  { result: "just_test" }.to_json
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

def image_template(img_url)
  {
    type: "image",
    originalContentUrl: img_url,
    previewImageUrl: img_url
  }
end

def video_template(video_url, img_url) 
  {
    type: "video",
    originalContentUrl: video_url,
    previewImageUrl: img_url
  }
end
