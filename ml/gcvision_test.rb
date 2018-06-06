require 'google/cloud/vision'
require 'google/cloud/storage'
require 'RMagick'

require 'pp'

project_id='radiant-octane-523'
image_path = ARGV[0]
# instantiates a client
vision = Google::Cloud::Vision.new project: project_id, credentials: "Vision_Project-5962574ea592.json"
Google::Cloud::Vision.default_max_faces = 10
puts image_path
face_image = vision.image(image_path)
text_image = vision.image(image_path)
landmark_image = vision.image(image_path)

annotations = vision.annotate(faces: 5) do |e|
	e.annotate face_image, faces: true, labels: true
	e.annotate text_image, text: true, labels: true
	e.annotate landmark_image, landmarks: true
end
puts "face features"
if annotations[0].faces.size.positive?
	puts annotations[0].faces.count
	puts annotations[0].faces.first.features.to_h if annotations[0].faces.size.positive?
end
puts "*" * 80

puts "text features"
puts annotations[1].text if annotations[1].text
puts "*" * 80

puts "landmark features"
if annotations[2].landmarks.size.positive?
	annotations[2].landmarks.each do |e|
		puts e
	end
end
puts "*" * 80


puts "labels"
annotations[0].labels.each do |l|
	puts l.description
end
puts "*" * 80
	
face_image.faces.each do |face|
	puts "Joy: #{face.likelihood.joy?}"
	puts "Anger: #{face.likelihood.anger?}"
	puts "Sorrow: #{face.likelihood.sorrow?}"
	puts "Surprise: #{face.likelihood.surprise?}"
end
exit
#
# use this API_Project-xxx.json key for accessing the Compute Engine default
# service account
storage = Google::Cloud::Storage.new project: project_id, credentials: "API_Project-990d187c7eac.json"

storage.buckets.each do |bucket|
	pp bucket
	puts bucket.name
end
exit

Google::Cloud::Vision.default_max_faces = 100

# the name of the image file to annotate
# file_name = "../ruby-docs-samples/vision/images/cat.jpg"
gcs_image_uri = vision.image("/Users/nickkaranatsios/Pictures/2018/03/IMG_0344.JPG")
source = { gcs_image_uri: gcs_image_uri }
image =  { source: source }
type = :FACE_DETECTION
features_element = { type: type }
features = [features_element]
requests_element = { image: image, features: features }
requests = [requests_element]
response = vision.batch_annotate_images(requests)
pp response
exit

faces = image.faces
face = faces.first
pp faces
exit



# performs label detection on the image file
labels = vision.image(file_name).labels

puts "labels:"
labels.each do |l|
	puts l.description
end
