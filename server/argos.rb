# Agitmemnons kingdom

require 'rubygems'
require 'sinatra'
require 'lib/agitmemnon'

get '/' do
  @repo_list = Agitmemnon::Client.repo_list
  erb :index
end

get '/r/:repo' do
  @repo_name = params[:repo]
  @repo = Agitmemnon::Client.new(@repo_name)
  erb :repo
end