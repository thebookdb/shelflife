ShelfLife Implementation Plan
Overview
Refactor ShelfLife to simplify the data model by:

Remove Scan model - scans go directly to libraries as LibraryItems
Add role to Library - support scanned_list per user (scan inbox)
Add nature to LibraryItem - physical vs virtual (replaces Library.virtual)
Remove virtual from Library - migrate to LibraryItem.nature
Add attribution to LibraryItem - track who added/updated items
Hide loan UI - keep DB fields, hide forms (Phase 2)
Keep visibility enum - SharedLink is Phase 2
Step 1: Database Migrations
1.1 Add role/user_id to libraries, nature/attribution to library_items
File: db/migrate/YYYYMMDDHHMMSS_add_role_and_nature_to_models.rb


class AddRoleAndNatureToModels < ActiveRecord::Migration[8.1]
  def change
    # Library: role enum + user ownership for scanned_list
    add_column :libraries, :role, :integer, default: 0, null: false
    add_column :libraries, :user_id, :integer, null: true
    add_index :libraries, :role
    add_index :libraries, :user_id
    add_index :libraries, [:user_id, :role], unique: true,
              where: "role = 1", name: "idx_libraries_user_scanned_list_unique"
    add_foreign_key :libraries, :users, column: :user_id, on_delete: :nullify

    # LibraryItem: nature enum + attribution
    add_column :library_items, :nature, :integer, default: 0, null: false
    add_column :library_items, :added_by_id, :integer, null: true
    add_column :library_items, :updated_by_id, :integer, null: true
    add_index :library_items, :nature
    add_index :library_items, :added_by_id
    add_index :library_items, :updated_by_id
    add_foreign_key :library_items, :users, column: :added_by_id, on_delete: :nullify
    add_foreign_key :library_items, :users, column: :updated_by_id, on_delete: :nullify
  end
end
1.2 Migrate LibraryItem.nature from Library.virtual
File: db/migrate/YYYYMMDDHHMMSS_populate_library_item_nature.rb


class PopulateLibraryItemNature < ActiveRecord::Migration[8.1]
  def up
    execute <<-SQL
      UPDATE library_items
      SET nature = 1
      WHERE library_id IN (SELECT id FROM libraries WHERE virtual = 1)
    SQL
  end

  def down
    execute "UPDATE library_items SET nature = 0"
  end
end
1.3 Remove virtual from libraries
File: db/migrate/YYYYMMDDHHMMSS_remove_virtual_from_libraries.rb


class RemoveVirtualFromLibraries < ActiveRecord::Migration[8.1]
  def change
    remove_index :libraries, :virtual
    remove_column :libraries, :virtual, :boolean, default: false, null: false
  end
end
1.4 Drop scans table
File: db/migrate/YYYYMMDDHHMMSS_drop_scans_table.rb


class DropScansTable < ActiveRecord::Migration[8.1]
  def up
    drop_table :scans
  end

  def down
    create_table :scans do |t|
      t.integer :product_id, null: false
      t.integer :user_id, null: false
      t.datetime :scanned_at, null: false
      t.timestamps
    end
    add_index :scans, [:product_id, :user_id, :scanned_at]
    add_foreign_key :scans, :products
    add_foreign_key :scans, :users
  end
end
Step 2: Model Changes
2.1 Update Library model
File: app/models/library.rb

Add belongs_to :user, optional: true
Add enum :role, { normal: 0, scanned_list: 1 }
Add scope :communal, -> { where(role: :normal) }
Add scanned_list_for(user) class method
Remove virtual? method
Remove physical_libraries and virtual_libraries scopes
Update default_libraries to remove virtual: true/false
2.2 Update LibraryItem model
File: app/models/library_item.rb

Add enum :nature, { physical: 0, virtual: 1 }
Add belongs_to :added_by, class_name: "User", optional: true
Add belongs_to :updated_by, class_name: "User", optional: true
Update scopes: virtual_items → where(nature: :virtual), physical_items → where(nature: :physical)
Update virtual_item? to use virtual? (enum method)
Update physical_item? to use physical? (enum method)
2.3 Update User model
File: app/models/user.rb

Remove has_many :scans
Add has_many :libraries, dependent: :nullify
Add scanned_list method: Library.scanned_list_for(self)
2.4 Update Product model
File: app/models/product.rb

Remove has_many :scans, dependent: :destroy
Rename broadcast_scan_updates → broadcast_product_updates
Remove the scan-related loop in the broadcast method (keep only product broadcast)
2.5 Delete Scan model
Delete: app/models/scan.rb

Step 3: Controller Changes
3.1 Delete ScansController
Delete: app/controllers/scans_controller.rb

3.2 Update ScannersController
File: app/controllers/scanners_controller.rb

Replace Current.user.scans.recent.last_n(10) with:


def recent_scanned_items
  Current.user.scanned_list
    .library_items
    .includes(:product)
    .order(date_added: :desc)
    .limit(10)
end
Change view params: recent_scans: → recent_items:

3.3 Update ProductsController
File: app/controllers/products_controller.rb

index action: Replace scans join with:


Product.joins(:library_items)
  .where(library_items: { library: Current.user.scanned_list })
  .order("library_items.date_added DESC")
  .distinct.limit(5)
3.4 Update LibrariesController
File: app/controllers/libraries_controller.rb

index: Filter to Library.communal
process_bulk_barcodes: Remove Scan.create!, add added_by: Current.user
3.5 Update LibraryItemsController
File: app/controllers/library_items_controller.rb

Add nature to strong params
Add handle_scanner_create method for scanner flow (checks params[:gtin])
Add attribution: added_by = Current.user on create, updated_by = Current.user on update
3.6 Update LibraryImportService
File: app/services/library_import_service.rb

Remove Scan.create! call (lines 34-39)
Add added_by: @user to LibraryItem.create!
Step 4: Route Changes
File: config/routes.rb

Remove line 54: resources :scans, only: [:index, :create, :destroy]
Remove line 77: resources :scans, only: [:index, :create] (API)
Step 5: JavaScript Changes
5.1 Update barcode_scanner_controller.js
File: app/javascript/controllers/barcode_scanner_controller.js

Line 331: Change fetch('/scans', ...) → fetch('/library_items', ...)

5.2 Update adaptive_barcode_scanner_controller.js
File: app/javascript/controllers/adaptive_barcode_scanner_controller.js

Line 319: Change fetch('/scans', ...) → fetch('/library_items', ...)

5.3 Update horizontal_barcode_scanner_controller.js
File: app/javascript/controllers/horizontal_barcode_scanner_controller.js

Line 214: Change fetch('/scans', ...) → fetch('/library_items', ...)

Step 6: View Component Changes
6.1 Update Scanner Views
Files:

app/components/scanners/index_view.rb
app/components/scanners/adaptive_view.rb
app/components/scanners/horizontal_view.rb
Changes:

initialize(recent_scans:, ...) → initialize(recent_items:, ...)
@recent_scans → @recent_items
Loop variable scan → item
scan.product → item.product
scan.created_at → item.date_added || item.created_at
Link /scans → /libraries/#{Current.user&.scanned_list&.id}
"Recent Scans" → "Recently Scanned"
6.2 Delete Scan Components
Delete directory: app/components/scans/

app/components/scans/index_view.rb
app/components/scans/scan_item_view.rb
6.3 Update NavigationView
File: app/components/shared/navigation_view.rb

Remove "Scans" link (lines 36-38)

6.4 Update Products::IndexView
File: app/components/products/index_view.rb

Remove "My Scans" button (lines 21-28)

6.5 Hide Loan UI in LibraryItems::EditView
File: app/components/library_items/edit_view.rb

Remove or comment out "Circulation" section (lent_to, due_date fields)

6.6 Hide Loan UI in LibraryItems::ShowView
File: app/components/library_items/show_view.rb

Remove circulation status section

Step 7: Delete Test Files
Delete:

test/models/scan_test.rb
test/controllers/scans_controller_test.rb
Step 8: Rebuild Assets

npm run build
Critical Files Summary
Category	Files
Migrations	4 new migration files
Models	library.rb, library_item.rb, user.rb, product.rb, delete scan.rb
Controllers	scanners_controller.rb, products_controller.rb, libraries_controller.rb, library_items_controller.rb, delete scans_controller.rb
Services	library_import_service.rb
JS Controllers	barcode_scanner_controller.js, adaptive_barcode_scanner_controller.js, horizontal_barcode_scanner_controller.js
Views	Scanner views (3), delete scans/ dir, navigation_view.rb, products/index_view.rb, library_items/edit_view.rb, library_items/show_view.rb
Routes	routes.rb
Tests	Delete 2 test files
Verification
After implementation:
Run migrations:


bin/rails db:migrate
Run tests:


bin/rails test
Start server and test manually:


bin/dev
Test scanner flow:

Open /scanner
Scan a barcode
Verify item appears in your scanned_list library
Navigate to Libraries → see your scanned_list
Test library item nature:

Add a physical item (default)
Change to virtual via edit form
Verify badge shows correctly
Test bulk import:

Import barcodes to a library
Verify items created with attribution
No scan records created
Verify removed routes return 404:

GET /scans → 404
POST /scans → 404
Implementation Order
Migrations (run in order)
Models (start with Library, then LibraryItem, then User, then Product, finally delete Scan)
Controllers (delete ScansController first, then update others)
Services
Routes
JavaScript controllers
View components
Delete test files
Rebuild assets
Run tests
Manual verification
