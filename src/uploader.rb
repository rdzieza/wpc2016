require 'aws-sdk'

class Uploader

  def self.upload_to_bucket(file, filename)
    obj = get_bucket.object(filename.downcase)
    if obj.upload_file(file)
      puts "Uploaded #{file}"
    else
      puts "Could not upload #{file}!"
    end
  end

  def self.send_to_sqs(json)
    p client
    p queue

    client.send_message({
                         queue_url: queue.queue_url,
                         message_body: json,
                         delay_seconds: 1
                     })
  end

  private

  AWS_REGION = 'eu-central-1'

  def self.get_bucket
    Aws::S3::Resource.new(region: AWS_REGION).bucket('166543-robson')
  end

  def self.client
    Aws::SQS::Client.new(region: AWS_REGION)
  end

  def self.queue
    client.create_queue({queue_name: 'tsowa-queue_name'})
  end

end