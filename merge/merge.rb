require 'csv'

# Read the old and new CSV files
old_data = CSV.read('old.csv', headers: true)
new_data = CSV.read('new.csv', headers: true)

# Initialize an array to store the merged data
merged_data = []

# Iterate over each row in the new data
new_data.each do |new_row|
  # Find the corresponding row in the old data based on 'GitHub Login'
  old_row = old_data.find { |r| r['GitHub Login'] == new_row['GitHub Login'] }

  # If a corresponding old row is found, update the new row's values
  if old_row
    new_row.each do |header, value|
      # Use the value from old_row if the value in new_row is blank or "No"
      if value.nil? || value.strip.empty? || value.strip == "No"
        new_row[header] = old_row[header]
      end
    end
  end

  # Add the updated new row to the merged data array
  merged_data << new_row
end

# Add any rows from old_data that are not in new_data
old_data.each do |old_row|
  unless new_data.any? { |new_row| new_row['GitHub Login'] == old_row['GitHub Login'] }
    merged_data << old_row
  end
end

# Write the merged data to a new CSV file
CSV.open('merged.csv', 'w') do |csv|
  # Write the headers
  csv << new_data.headers

  # Write each row of the merged data
  merged_data.each { |row| csv << row }
end

puts "Merging complete. Check merged.csv for the result."
