namespace :scraper do
  desc "fetch craigslist posts from 3taps"
  task scrape: :environment do
  	# fetched from scraper file, will be refactored to use in this rake task


  	# allows you to open url's in your script:
		require 'open-uri'
		require 'json'

		# set api token and url
		auth_token = "3053396b65d3f5badf510c8b1059a76c"
		polling_url = "http://polling.3taps.com/poll"


		# grab data until up to date
		loop do


			# specify request parameters
			params = {
				auth_token: auth_token,
				anchor: Anchor.first.value,
				source: "CRAIG",
				category_group: "RRRR",
				category: "RHFR",
				# if there's a period in the middle, use the hash rocket symbol instead
				'location.city' => "USA-CHI-CHI",
				retvals: "location,external_url,heading,body,timestamp,price,images,annotations"
			}

			# prepare api request
			# start with the base url, then add parameters from the params variable above
			# parse method, takes string and converts it into a uri object, which we need in a data request
			uri = URI.parse(polling_url)
			# takes the array of paramaters and converts it into the format with www and = signs
			uri.query = URI.encode_www_form(params)

			# submit request
			# wrap result in JSON.parse() to print out in a better fomat
			result = JSON.parse(open(uri).read)

			# display results to screen
			# can play with result hash and get different values from it (play w/arrays and hashes)
			# puts result["postings"].first["heading"]
			# puts result["postings"].first["location"]["locality"]

			#how to print out and inspect images for future use:
			#puts result["postings"].first["images"].first["full"]




			result["postings"].each do |posting|
				# create new post
				@post = Post.new
				@post.heading = posting["heading"]
				@post.body = posting["body"]
				@post.price = posting["price"]
				# uses the location database to set the post neighborhood attribute of each post to the location name, so its easier to read
				@post.neighborhood = Location.find_by(code: posting["location"]["locality"]).name unless Location.find_by(code: posting["location"]["locality"]) == nil
				#@post.neighborhood = Location.find_by(code: posting["location"]["locality"]).try(name)
				@post.external_url = posting["external_url"]
				@post.timestamp = posting["timestamp"]



				# if posting["annotations"]["bedrooms"].present?
	   		#  		@post.bedrooms = posting["annotations"]["bedrooms"]
	  		# 	end
				# scrape for every bedroom
				@post.bedrooms = posting["annotations"]["bedrooms"] if posting["annotations"]["bedrooms"].present?
			  @post.bathrooms = posting["annotations"]["bathrooms"] if posting["annotations"]["bathrooms"].present?
			  @post.sqft = posting["annotations"]["sqft"] if posting["annotations"]["sqft"].present?
			  @post.cats = posting["annotations"]["cats"] if posting["annotations"]["cats"].present?
			  @post.dogs = posting["annotations"]["dogs"] if posting["annotations"]["dogs"].present?
			  @post.w_d_in_unit = posting["annotations"]["w_d_in_unit"] if posting["annotations"]["w_d_in_unit"].present?
			  @post.street_parking = posting["annotations"]["street_parking"] if posting["annotations"]["street_parking"].present?


				# save post
				@post.save

				# loop over images and save to imagas database
				posting["images"].each do |image|
					@image = Image.new
					@image.url = image["full"]
					@image.post_id = @post.id
					@image.save
				end
			end

			# we need to update the anchor value so the application makes requests with different anchor values each time
			# every time the rake task is ran, the anchor value will be updated
			Anchor.first.update(value: result["anchor"])
		
			# we want the loop to stop when the postings hash is empty
			break if result["postings"].empty?

		end
	end




	# desc "destroys all the posts in the database"
	# task destroy_all_posts: :environment do
	# 	# Post.destroy_all
	# 	Post.all.each |post|
	# 		if post.created_at < 6.hours.ago
	# 			post.destroy
	# 		end
	# 	end
	# end

	desc "destroys all the posts in the database"
	task destroy_all_posts: :environment do
		Post.destroy_all
	end



	desc "save neighborhood codes in a reference table"
	task scrape_neighborhoods: :environment do
		require 'open-uri'
		require 'json'
		# set api token and url
		auth_token = "3053396b65d3f5badf510c8b1059a76c"
		location_url = "http://reference.3taps.com/locations"
		# specify request parameters
		params = {
			auth_token: auth_token,
			level: "locality",
			city: "USA-CHI-CHI"
		}
		# prepare api request
		# start with the base url, then add parameters from the params variable above
		# parse method, takes string and converts it into a uri object, which we need in a data request
		uri = URI.parse(location_url)
		# takes the array of paramaters and converts it into the format with www and = signs
		uri.query = URI.encode_www_form(params)
		# submit request
		# wrap result in JSON.parse() to print out in a better fomat
		result = JSON.parse(open(uri).read)

		#puts JSON.pretty_generate result
		# stores results in the database
		result["locations"].each do |location|
			@location = Location.new
			@location.code = location["code"]
			@location.name = location["short_name"]
			@location.save
		end
	end


end

