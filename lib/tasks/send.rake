require './fetch_ig.rb'

namespace :send do
    desc "每五分鐘傳送新的IG PosT By Sub"
    task :ig_new_items do
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
                            puts "五分鐘內"
                        else 
                            break
                        end
                    end

                    latest_posts.each do |post_id|
                        post_json = getInstagramJson("https://www.instagram.com/p/#{post_id}/")
                        media = JSON.parse(post_json)['entry_data']['PostPage'][0]['graphql']['shortcode_media']
                        if media['edge_sidecar_to_children']
                            media['edge_sidecar_to_children']['edges'].each do |item|
                                
                                if item['node']['is_video'] 
                                    message = video_template(item['node']['video_url'], item['node']['display_url'])
                                else
                                    message = image_template(item['node']['display_url'])
                                end
                                puts message
                                client.push_message(user.source_id, message)
                            end
                        else 
                            media['is_video'] ? message = video_template(media['video_url'], media['display_url']) : message = image_template(media['display_url'])
                            client.push_message(user.source_id, message)
                        end
                    end
                rescue
                    puts "HEHEHE ERROR"
                end
            end
        end
    end
end 

