require 'sinatra'
require 'aws-sdk'
require 'pony'
require 'sendmail'
require 'prawn'
require 'json'

while true
  s3_client = Aws::S3::Client.new(region: 'eu-central-1') 
  sqs = Aws::SQS::Client.new(region: 'eu-central-1') 
  queue = sqs.create_queue({queue_name: "tsowa-queue_name"})  
  
  resp = sqs.receive_message({
    queue_url: queue.queue_url,
    message_attribute_names: ["MessageAttributeName"],
    max_number_of_messages: 1,
    visibility_timeout: 1,
    wait_time_seconds: 1,
  })
  
  if resp.messages[0].body.nil?
    puts "mail will be send from: " + resp.messages[0].body
    msg = JSON.parse(resp.body)
    album_name = msg["album_name"]
    email = msg["email"]
    files = msg["files"]
    if (album_name.nil? && email.nil? && files.nil?)
      FileUtils.mkdir_p 'files' # temporary directory
      files.each do |filename|
        # save every choosed files to files/ directory
        s3_client.get_object(
        bucket: '166543-robson', 
        key: filename, 
        response_target: "files/" + filename)
      end

      pdf = Prawn::Document.new
      files.each do |f|
        title = "files/" + f # path to file
        pdf.image title, :at => [50, 250], :width => 300, :height => 350
        pdf.start_new_page
      end

      pdf.render_file "files/" + name # save pdf to file
      
      # send mail
      Pony.mail(
        :to => email, 
        :from => 'fake@wpc2016.uek.krakow.pl', 
        :subject => "Your album: #{name}", 
        :body => 'Check attachments.',
        :attachments => {"#{name}" => File.read("files/" + name) })
          
      # delete files from bucket, remove temporary dir
      FileUtils.remove_dir "files";
      files.each do |f|
        obj = get_bucket.object(f)
        obj.delete
      end
      
      resp = client.delete_message({
        queue_url: queue.queue_url, # required
        receipt_handle: "String", # required
      })
      puts resp.to_h
    end
  end
end

