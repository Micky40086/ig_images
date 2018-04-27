require 'sinatra/activerecord'

class User < ActiveRecord::Base
  validates_presence_of :source_id
  validates_presence_of :identity
end

def hehe(source)
  
end