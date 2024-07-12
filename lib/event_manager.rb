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
  name = row[:first_name] # first variable read by erb template

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode) # second variable read by erb template

  form_letter = erb_template.result(binding) # the code is directly set in the ERB escape tags

  puts form_letter
end
