# Agitmemnons kingdom

require 'rubygems'
require 'sinatra'
require '/home/git/agitmemnon/lib/agitmemnon'
require 'cgi'

def gravatar(email, size = 30)
  gid = Digest::MD5.hexdigest(email.to_s.strip.downcase)
  url = "http://www.gravatar.com/avatar/#{gid}?s=#{size}&d=http%3A%2F%2Fgithub.com%2Fimages%2Fgravatars%2Fgravatar-#{size}.png"
  "<img title=\"#{email}\" src=\"#{url}\">"
end

get '/' do
  erb :index
end

get '/*/refs' do
  @tab = 'refs'
  @repo_name = params[:splat].first
  @repo = Agitmemnon::Client.new(@repo_name)
  erb :refs
end

get '/*/log/:sha' do
  @tab = 'log'
  @repo_name = params[:splat].first
  @repo = Agitmemnon::Client.new(@repo_name)
  @commit = @repo.commit(params[:sha])
  erb :log
end

get '/*/log' do
  @tab = 'log'
  @repo_name = params[:splat].first
  @repo = Agitmemnon::Client.new(@repo_name)
  @commit = @repo.head_commit
  erb :log
end

get '/*/commit/:sha' do
  @tab = 'source'
  @repo_name = params[:splat].first
  @repo = Agitmemnon::Client.new(@repo_name)
  @commit = @repo.commit(params[:sha])
  @tree = @commit.tree
  erb :repo
end

get '/*/commit/:sha/*/:object_sha' do
  @tab = 'source'
  @repo_name = params[:splat][0]
  @repo = Agitmemnon::Client.new(@repo_name)
  @path = params[:splat][1]
  @commit = @repo.commit(params[:sha])
  @object = @repo.get(params[:object_sha])
  if @object['type'] == 'tree'
    @tree = JSON.parse(@object['json'])
    erb :repo
  else
    @data = Agitmemnon::Client.expand(@object['data'])
    erb :blob
  end
end

get '/a' do
  erb :admin
end

get '/*' do
  @tab = 'source'
  @repo_name = params[:splat].first
  @repo = Agitmemnon::Client.new(@repo_name)
  @commit = @repo.head_commit
  @tree = @commit.tree
  erb :repo
end

