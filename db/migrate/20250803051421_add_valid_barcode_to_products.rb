class AddValidBarcodeToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :valid_barcode, :boolean, default: true
  end
end
