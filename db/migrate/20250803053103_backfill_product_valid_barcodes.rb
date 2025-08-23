class BackfillProductValidBarcodes < ActiveRecord::Migration[8.0]
  def up
    say "Backfilling valid_barcode for existing products..."

    Product.find_each do |product|
      valid_barcode = BarcodeValidationService.valid_barcode?(product.ean)
      product.update_column(:valid_barcode, valid_barcode)
      print "."
    end

    say "\nBackfill complete!"
  end

  def down
    # Set all products back to valid (the original default)
    Product.update_all(valid_barcode: true)
  end
end
