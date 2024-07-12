require "csv"
require "google/apis/civicinfo_v2"
require "erb" # load ERB library
require "time"
require "date"

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

puts "Event Manager Initialized!"

# using CSV parser from Ruby's library
contents = CSV.open(
  "event_attendees.csv",
  headers: true,
  header_converters: :symbol
)

# create ERB template from the contents of the template (.erb) file
template_letter = File.read("form_letter.erb")
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0] # assign id for file names using first column from .csv, using index value since no available symbol
  name = row[:first_name] # first variable read by erb template
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode) # second variable read by erb template

  form_letter = erb_template.result(binding) # the code is directly set in the ERB escape tags

  phone_number = clean_phone_number(row[:homephone])

  date_and_time = row[:regdate]

  week_day = Date.strptime(date_and_time, "%D").strftime("%A")

  hour = Time.strptime(date_and_time, "%D %R").strftime("%R")

  # save_thank_you_letter(id, form_letter)
  puts "#{name} #{phone_number} on a #{week_day} at #{hour}"
end
