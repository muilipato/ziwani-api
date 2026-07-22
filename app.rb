require "dotenv/load"
require 'sinatra'
require 'json'
require 'aws-sdk-s3'
require 'rack/cors'

use Rack::Cors do
  allow do
    origins '*'

    resource '*',
      headers: :any,
      methods: [:get]
  end
end

s3 = Aws::S3::Client.new(
 region: ENV["AWS_REGION"],
 access_key_id: ENV["AWS_ACCESS_KEY_ID"],
 secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
)

BUCKET = ENV["S3_BUCKET"]

get "/gallery" do #returns available albums

 content_type :json

 result =
 s3.list_objects_v2(
   bucket: BUCKET,
   delimiter: "/"
 )

  albums = result.common_prefixes.map do |prefix|
    {
      name: prefix.prefix.chomp("/")
    }
  end

  content_type :json
  albums.to_json

end

get "/gallery/:album" do #returns images according to albums
  album = params[:album]

  result = s3.list_objects_v2(
    bucket: BUCKET,
    prefix: "#{album}/"
  )

  images = result.contents
  .reject { |obj| obj.key.end_with?("/") }  
  .map do |obj|
    {
      name: File.basename(obj.key),
      key: obj.key,
      size: obj.size,
      last_modified: obj.last_modified,
      url: "https://#{BUCKET}.s3.amazonaws.com/#{obj.key}"
    }
  end

  content_type :json
  images.to_json

end

set :bind, "0.0.0.0"
set :port, ENV.fetch("PORT", 8080)