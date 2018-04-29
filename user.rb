require 'sinatra/activerecord'
require 'net/http'

class User < ActiveRecord::Base
  validates_presence_of :source_id
  validates_presence_of :identity
  has_many :ig_items
end

class IgItem < ActiveRecord::Base
  validates_presence_of :account
  belongs_to :user
end

def source_user(source_json)
  case source_json['type']
  when 'user'
    User.find_or_create_by(source_id: source_json['userId'], identity: 0)
  when 'group'
    User.find_or_create_by(source_id: source_json['groupId'], identity: 1)
  end
end

def handle_message(user,message)
  if message.include? 'HEHE'
    serial_num = message
    serial_num.slice!('HEHE')
    serial_num = serial_num.strip
    uri = URI("https://www.instagram.com/#{serial_num}/")
    res = Net::HTTP.get_response(uri)
    if res.code == '200'
      user.ig_items.find_or_create_by(account: serial_num)
      return "已訂閱 #{serial_num}"
    end
    return "找不到此帳號"
  end
end