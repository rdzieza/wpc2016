require 'sinatra'
require 'aws-sdk'
require 'pony'
require 'sendmail'
require 'prawn'
require 'json'

while true
  s3_client = Aws::S3::Client.new(region: 'eu-central-1') 
  sqs = Aws::SQS::Client.new(region: 'eu-central-1') 
  queue = sqs.create_queue({queue_name: 'tsowa-queue_name'})
  
  resp = sqs.receive_message({
    queue_url: queue.queue_url,
    message_attribute_names: ['MessageAttributeName'],
    max_number_of_messages: 1,
    visibility_timeout: 1,
    wait_time_seconds: 1,
  })
  
  unless resp.messages[0].nil?
    puts resp.messages[0]
    msg = JSON.parse(resp.messages[0].body)
    album_name = msg['album_name']
    email = msg['email']
    files = msg['files']
    unless album_name.nil? && email.nil? && files.nil?
      puts 'make dir, save files'
      FileUtils.mkdir_p 'files' # temporary directory
      files.each do |filename|
        # save every choosed files to files/ directory
        s3_client.get_object(
        bucket: '166543-robson', 
        key: filename, 
        response_target: 'files/' + filename)
      end

      pdf = Prawn::Document.new
      pdf.text name, :align => :center

      files.each do |f|
        title = "files/" + f # path to file
        pdf.image title, :fit => [300, 300], :position => :center, :vposition => :center
        pdf.start_new_page
      end

      pdf.render_file "files/" + album_name # save pdf to file
      
      # send mail
      Pony.mail(
        :to => email, 
        :from => 'fake@wpc2016.uek.krakow.pl', 
        :subject => "Your album: #{album_name}",
        :body => 'Check attachments.',
        :attachments => {"#{album_name}" => File.read("files/" + album_name) })
          
      # delete files from bucket, remove temporary dir
      FileUtils.remove_dir "files";
      files.each do |f|
        obj = Aws::S3::Resource.new(region: 'eu-central-1').bucket('166543-robson').object(f)
        obj.delete
      end
      
      resp = sqs.delete_message({
        queue_url: queue.queue_url, # required
        receipt_handle: resp.messages[0].receipt_handle # required
      })
    end
  end
end

