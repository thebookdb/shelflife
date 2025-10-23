# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create default libraries
Library.default_libraries.each do |library_attrs|
  Library.find_or_create_by(name: library_attrs[:name]) do |library|
    library.description = library_attrs[:description]
  end
end

puts "Created #{Library.count} libraries: #{Library.pluck(:name).join(', ')}"

# Create default conditions
default_conditions = [
  { name: 'Mint', description: 'Perfect condition, like new', sort_order: 1 },
  { name: 'Like New', description: 'Minimal wear, excellent condition', sort_order: 2 },
  { name: 'Very Good', description: 'Minor wear, still in great shape', sort_order: 3 },
  { name: 'Good', description: 'Normal wear from use', sort_order: 4 },
  { name: 'Fair', description: 'Noticeable wear but fully functional', sort_order: 5 },
  { name: 'Poor', description: 'Heavy wear, may have damage', sort_order: 6 },
  { name: 'Damaged', description: 'Significant damage affecting functionality', sort_order: 7 }
]

default_conditions.each do |condition_attrs|
  Condition.find_or_create_by(name: condition_attrs[:name]) do |condition|
    condition.description = condition_attrs[:description]
    condition.sort_order = condition_attrs[:sort_order]
  end
end

puts "Created #{Condition.count} conditions: #{Condition.pluck(:name).join(', ')}"

# Create some sample products for testing
sample_products = [
  {
    gtin: '9780143058144',
    title: 'The Hitchhiker\'s Guide to the Galaxy',
    author: 'Douglas Adams',
    publisher: 'Pan Books',
    product_type: 'book',
    genre: 'Science Fiction'
  },
  {
    gtin: '9780747532743',
    title: 'Harry Potter and the Philosopher\'s Stone',
    author: 'J.K. Rowling',
    publisher: 'Bloomsbury',
    product_type: 'book',
    genre: 'Fantasy'
  }
]

sample_products.each do |product_attrs|
  Product.find_or_create_by(gtin: product_attrs[:gtin]) do |product|
    product_attrs.each { |key, value| product.send("#{key}=", value) }
  end
end

puts "Created #{Product.count} sample products"
