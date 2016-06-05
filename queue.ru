require 'sinatra'
require 'aws-sdk'
require 'pony'
require 'sendmail'
require 'prawn'

def send_mail_from_queue
    FileUtils.mkdir_p 'files' # temporary directory
  
  s3_client = Aws::S3::Client.new(region: 'eu-central-1')
  params[:files].each do |filename|
    # save every choosed files to files/ directory
    s3_client.get_object(
      bucket: '166543-robson', 
      key: filename, 
      response_target: "files/" + filename)
  end

  pdf = Prawn::Document.new
  params[:files].each do |f|
    title = "files/" + f # path to file
    pdf.image title, :at => [50, 250], :width => 300, :height => 350
    pdf.start_new_page
  end

  pdf.render_file "files/" + name # save pdf to file
  
  # send mail
  mail_subject = "Your album: #{name}"
  Pony.mail(
    :to => email, 
    :from => 'fake@wpc2016.uek.krakow.pl', 
    :subject => mail_subject, 
    :body => 'Check attachments.',
    :attachments => {"#{name}" => File.read("files/" + name) })
    
  # delete files from bucket, remove temporary dir
  FileUtils.remove_dir "files";
  params[:files].each do |f|
    obj = get_bucket.object(f)
    obj.delete
  end
end

