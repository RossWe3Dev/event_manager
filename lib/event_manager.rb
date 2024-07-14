require "csv"
require "google/apis/civicinfo_v2"
require "erb" # load ERB library

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = File.read("secret.key").strip

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: "country",
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials # no longer need to define legislator names or strings, parsed by ERB escape tags
  rescue
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir("output") unless Dir.exist?("output")

  filename = "output/thanks_#{id}.html"

  # open file with the 'w' tag for writing
  File.open(filename, "w") do |file|
    file.puts form_letter
  end
end

def clean_phone_number(phone_num)
  numbers_only = phone_num.to_s.delete("^0-9")
  if numbers_only.length == 10
    numbers_only.insert(3, "-").insert(-5, "-")
  elsif numbers_only[0] == "1" && numbers_only.length == 11
    numbers_only[1..10].insert(3, "-").insert(-5, "-")
  else
    "Invalid number"
  end
end

def ads_info_count(array)
  array.reduce(Hash.new(0)) { |h, k| h[k] += 1; h }.sort_by { |_k, v| v }.reverse.to_h
end

def display_info(hash)
  hash.each do |k, v|
    v == 1 ? (puts "#{k}, #{v} time") : (puts "#{k}, #{v} times")
  end
end

puts "Event Manager Initialized!"

# using CSV parser from Ruby's library
contents = CSV.open(
  "event_attendees.csv",
  headers: true,
  header_converters: :symbol
)

# create ERB template from the contents of the template (.erb) file
# template_letter = File.read("form_letter.erb")
# erb_template = ERB.new template_letter

week_days = []
hours = []

contents.each do |row|
  # id = row[0]
  # name = row[:first_name]
  # zipcode = clean_zipcode(row[:zipcode])
  # legislators = legislators_by_zipcode(zipcode)

  # form_letter = erb_template.result(binding)

  # save_thank_you_letter(id, form_letter)

  phone_number = clean_phone_number(row[:homephone])

  date_and_time = DateTime.strptime(row[:regdate], "%D %R")

  week_day = date_and_time.strftime("%A")
  week_days.push(week_day)

  hour = date_and_time.strftime("%H:00")
  hours.push(hour)

  puts "#{name} #{phone_number} Registered on a #{week_day} at #{hour}"
end

puts "\nUsers registered at:"
display_info(ads_info_count(hours))

puts "\nUsers registered on a:"
display_info(ads_info_count(week_days))
