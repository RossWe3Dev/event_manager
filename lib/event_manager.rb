require "csv"
require "google/apis/civicinfo_v2"

# separate the logic for a clean code
def clean_zipcode(zipcode)
  # succint one-liner, all called methods apply only if the argument needs modifications
  zipcode.to_s.rjust(5, "0")[0..4]

  # if zipcode.nil?
  #   "00000"
  # elsif zipcode.length < 5
  #   zipcode.rjust(5, "0")
  # elsif zipcode.length > 5
  #   zipcode[0..4]
  # else
  #   zipcode
  # end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = File.read("secret.key").strip

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: "country",
      roles: %w[legislatorUpperBody legislatorLowerBody]
    )
    legislators = legislators.officials

    # legislator_names = legislators.map do |legislator|
    #   legislator.name
    # end

    # or the cleaner one liner
    legislator_names = legislators.map(&:name)

    legislator_names.join(", ")
  rescue
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

puts "Event Manager Initialized!"

# contents = File.read("event_attendees.csv")
# puts contents

# puts File.exist? "event_attendees.csv"

# ITERATION 0: building our own CSV parser
# lines = File.readlines("event_attendees.csv")
# lines.each_with_index do |line, index| # each_with_index to skip header, index == 0
#   next if index == 0

#   columns = line.split(",") # split each row into an array of column elements by the commmas
#   name = columns[2] # name is columumn 3 so index number 2 of each row
#   puts name
# end

# ITERATION 1: using CSV parser from Ruby's library
contents = CSV.open(
  "event_attendees.csv",
  headers: true,
  header_converters: :symbol
)

contents.each do |row|
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  legislator_string = legislators_by_zipcode(zipcode) # moved the code block into its own method

  puts "#{name} #{zipcode} #{legislator_string}"
end
