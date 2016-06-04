require 'sinatra'
require 'haml'
require 'prawn'
require 'aws-sdk'
require 'pony'
require 'sendmail'

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
  params[:files].each {|f| result += f.to_s}
  email = params[:email]

  pdf = Prawn::Document.new
  params[:files].each do |f|
    puts get_bucket.object(f).etag
    pdf.image img, :at => [50, 250], :width => 300, :height => 350
    pdf.start_new_page
  end

  if params[:file_name].include? ".pdf"
    name = params[:file_name]
  else
    name = params[:file_name] + ".pdf"
  end

  pdf.render_file "files/" + name
  
  Pony.mail(
    :to => email, 
    :from => 'fake@wpc2016.uek.krakow.pl', 
    :subject => 'Your album: #{name}', 
    :body => 'Check attachments.',
    :attachments => {"#{name}" => File.read(pdf) })

  result
end

def get_bucket
  Aws::S3::Resource.new(region: 'eu-central-1').bucket('166543-robson')
end

def upload(file, filename)
  obj = get_bucket.object(filename)

  if obj.upload_file(file)
    puts "Uploaded #{file} to bucket #{bucket}"
  else
    puts "Could not upload #{file} to bucket #{bucket}!"
  end
end