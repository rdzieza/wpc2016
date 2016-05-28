require 'sinatra'
require 'haml'


get '/' do
  haml :home
end

post '/upload' do

  	filename = params[:file][:filename]
  	tempfile = params[:file][:tempfile]
  	target = "files/#{filename}"
  	File.open(target, 'wb') {|f| f.write tempfile.read }
	redirect "/list"
end

get '/list' do
	@files = Dir.entries("files").select {|f| !File.directory? f}
	haml :list
end

post '/save' do
	result = ""
	params[:files].each {|f| result += f.to_s}
	result
end

