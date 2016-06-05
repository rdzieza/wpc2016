require 'sinatra'
require 'haml'
require 'prawn'
require 'aws-sdk'
require 'json'

get '/' do
  haml :home
end

post '/upload' do
  puts "/upload"
  tempfile = params[:file][:tempfile]
  filename = params[:file][:filename]
  puts tempfile.path
  
  upload(tempfile.path, filename)
  redirect "/list"
end

get '/list' do
  @files = get_bucket.objects.collect(&:key)
  haml :list
end

post '/save' do
  result = ""
  email = params[:email]
  files = params[:files]  
  
  if params[:file_name].include? ".pdf"
    name = params[:file_name]
  else
    name = params[:file_name] + ".pdf"
  end
  
  album = {:album_name => name, :email => email, :files => files}
  album_json = JSON.generate(album)
  puts album_json
  
  sqs = Aws::SQS::Client.new(region: 'eu-central-1')
  queue = sqs.create_queue({queue_name: "tsowa-queue_name"})
  re1 = sqs.send_message({
    queue_url: queue.queue_url,
    message_body: album_json,
    delay_seconds: 1
  })
  puts re1.to_h
  
  result
end

def get_bucket
  Aws::S3::Resource.new(region: 'eu-central-1').bucket('166543-robson')
end

def upload(file, filename)
  obj = get_bucket.object(filename.downcase)

  if obj.upload_file(file)
    puts "Uploaded #{file}}"
  else
    puts "Could not upload #{file}!"
  end
end