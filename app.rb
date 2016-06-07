require 'sinatra'
require 'haml'
require 'prawn'
require 'aws-sdk'
require 'json'

get '/' do
  haml :home
end

post '/upload' do
  tempfile = params[:file][:tempfile]
  filename = params[:file][:filename]
  puts tempfile.path
  
  Uploader.upload_to_bucket(tempfile.path, filename)
  redirect '/list'
end

get '/list' do
  @files = get_bucket.objects.collect(&:key)
  haml :list
end

post '/save' do
  result = ''
  email = params[:email]
  files = params[:files]

  (params[:file_name].include? '.pdf') ? name = params[:file_name] : name = params[:file_name] + '.pdf'

  album = {
      album_name: name,
      email: email,
      files: files
  }

  Uploader.send_to_sqs(JSON.generate(album))

  result
end