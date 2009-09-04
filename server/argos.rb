# Agitmemnons kingdom

require 'rubygems'
require 'sinatra'
require 'lib/agitmemnon'
require 'cgi'

def gravatar_url_for(email, size = 30)
  gid = Digest::MD5.hexdigest(email.to_s.strip.downcase)
  "http://www.gravatar.com/avatar/#{gid}?s=#{size}&d=http%3A%2F%2Fgithub.com%2Fimages%2Fgravatars%2Fgravatar-#{size}.png"
end

get '/' do
  @repo_list = Agitmemnon::Client.repo_list
  erb :index
end

get '/*/log' do
  @tab = 'log'
  @repo_name = params[:splat].first
  @repo = Agitmemnon::Client.new(@repo_name)
  @commit = @repo.head_commit
  erb :log
end

get '/*/refs' do
  @tab = 'refs'
  @repo_name = params[:splat].first
  @repo = Agitmemnon::Client.new(@repo_name)
  erb :refs
end

get '/*' do
  @tab = 'source'
  @repo_name = params[:splat].first
  @repo = Agitmemnon::Client.new(@repo_name)
  @commit = @repo.head_commit
  erb :repo
end

get '/a' do
  erb :admin
end

