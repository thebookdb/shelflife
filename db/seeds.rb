# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create default libraries
Library.default_libraries.each do |library_attrs|
  Library.find_or_create_by(name: library_attrs[:name]) do |library|
    library.description = library_attrs[:description]
  end
end

puts "Created #{Library.count} libraries: #{Library.pluck(:name).join(", ")}"

# Create default conditions
default_conditions = [
  {name: "Mint", description: "Perfect condition, like new", sort_order: 1},
  {name: "Like New", description: "Minimal wear, excellent condition", sort_order: 2},
  {name: "Very Good", description: "Minor wear, still in great shape", sort_order: 3},
  {name: "Good", description: "Normal wear from use", sort_order: 4},
  {name: "Fair", description: "Noticeable wear but fully functional", sort_order: 5},
  {name: "Poor", description: "Heavy wear, may have damage", sort_order: 6},
  {name: "Damaged", description: "Significant damage affecting functionality", sort_order: 7}
]

default_conditions.each do |condition_attrs|
  Condition.find_or_create_by(name: condition_attrs[:name]) do |condition|
    condition.description = condition_attrs[:description]
    condition.sort_order = condition_attrs[:sort_order]
  end
end

puts "Created #{Condition.count} conditions: #{Condition.pluck(:name).join(", ")}"

# Create default item statuses
default_item_statuses = [
  {name: "Available", description: "Item is available for use or checkout"},
  {name: "Checked Out", description: "Item is currently lent to someone"},
  {name: "Missing", description: "Item cannot be located"},
  {name: "Damaged", description: "Item is damaged and not available"},
  {name: "In Repair", description: "Item is being repaired"},
  {name: "Retired", description: "Item is no longer part of the collection"}
]

default_item_statuses.each do |attrs|
  ItemStatus.find_or_create_by(name: attrs[:name]) do |s|
    s.description = attrs[:description]
  end
end

puts "Created #{ItemStatus.count} item statuses: #{ItemStatus.pluck(:name).join(", ")}"

# Create default ownership statuses
default_ownership_statuses = [
  {name: "Owned", description: "Fully owned by the library"},
  {name: "Borrowed", description: "Borrowed from someone else"},
  {name: "On Loan", description: "Loaned out to another party"},
  {name: "Consignment", description: "Held on consignment"}
]

default_ownership_statuses.each do |attrs|
  OwnershipStatus.find_or_create_by(name: attrs[:name]) do |s|
    s.description = attrs[:description]
  end
end

puts "Created #{OwnershipStatus.count} ownership statuses: #{OwnershipStatus.pluck(:name).join(", ")}"

# Create default acquisition sources
default_acquisition_sources = [
  {name: "Purchased", description: "Bought new or secondhand"},
  {name: "Gift", description: "Received as a gift"},
  {name: "Donated", description: "Donated to the collection"},
  {name: "Trade", description: "Acquired via trade"},
  {name: "Found", description: "Found or unclaimed"}
]

default_acquisition_sources.each do |attrs|
  AcquisitionSource.find_or_create_by(name: attrs[:name]) do |s|
    s.description = attrs[:description]
  end
end

puts "Created #{AcquisitionSource.count} acquisition sources: #{AcquisitionSource.pluck(:name).join(", ")}"

# Create some sample products for testing
sample_products = [
  {
    gtin: "9780143058144",
    title: "The Hitchhiker's Guide to the Galaxy",
    author: "Douglas Adams",
    publisher: "Pan Books",
    product_type: "book",
    genre: "Science Fiction"
  },
  {
    gtin: "9780747532743",
    title: "Harry Potter and the Philosopher's Stone",
    author: "J.K. Rowling",
    publisher: "Bloomsbury",
    product_type: "book",
    genre: "Fantasy"
  }
]

sample_products.each do |product_attrs|
  Product.find_or_create_by(gtin: product_attrs[:gtin]) do |product|
    product_attrs.each { |key, value| product.send("#{key}=", value) }
  end
end

puts "Created #{Product.count} sample products"
