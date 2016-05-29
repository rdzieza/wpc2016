require 'sinatra'
require 'haml'
require 'prawn'

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
	# @files = Dir.entries("files").select {|f| !File.directory? f}
	@files = Dir.glob("files/*.{jpg,gif}")
	haml :list
end

post '/save' do
	result = ""
	params[:files].each {|f| result += f.to_s}
	
	
	pdf = Prawn::Document.new

	params[:files].each do |f|
		title = "files/" + f.to_s
		pdf.image title, :at => [50, 250], :width => 300, :height => 350
		pdf.start_new_page
	end


	pdf.render_file "files/outcome.pdf"

	result
end

