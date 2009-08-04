# Agitmemnons kingdom

require 'rubygems'
require 'sinatra'
require 'lib/agitmemnon'
require 'cgi'

get '/' do
  @repo_list = Agitmemnon::Client.repo_list
  erb :index
end

get '/r/:repo' do
  @repo_name = params[:repo]
  @repo = Agitmemnon::Client.new(@repo_name)
  erb :repo
end

get '/r/:repo/commit/:sha' do
  @repo_name = params[:repo]
  @repo = Agitmemnon::Client.new(@repo_name)
  @patch = @repo.diff(params[:sha])
  erb :commit, :layout => false
end

get '/r/:repo/tree/:sha' do
  @repo_name = params[:repo]
  @repo = Agitmemnon::Client.new(@repo_name)
  erb :tree, :layout => false
end