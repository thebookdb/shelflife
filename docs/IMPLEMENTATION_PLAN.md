# ShelfLife Implementation Plan

## Overview

This document outlines the changes required to implement the simplified ShelfLife data model. The focus is on removing unnecessary complexity (Scan model) and adding the new features discussed (Library roles, LibraryItem nature, user attribution).

---

## Phase 1: Core Model Changes

### 1.1 Remove Scan Model

**Files to Remove:**
- `app/models/scan.rb`
- `app/controllers/scans_controller.rb`
- `app/components/scans/index_view.rb`
- `app/components/scans/scan_item_view.rb`
- `app/views/scanners/scan.html.erb` (already deleted)

**Routes to Remove:**
```ruby
# Remove from config/routes.rb:
resources :scans, only: [:index]
```

**Database Migration:**
```ruby
# db/migrate/XXXXXX_drop_scans.rb
class DropScans < ActiveRecord::Migration[8.0]
  def change
    drop_table :scans
  end
end
```

**Navigation Updates:**
- Remove "My Scans" button from navigation components
- Update any links to `/scans` to point to user's scanned list instead

---

### 1.2 Add Library Role

**Migration:**
```ruby
# db/migrate/XXXXXX_add_role_to_libraries.rb
class AddRoleToLibraries < ActiveRecord::Migration[8.0]
  def change
    add_column :libraries, :role, :string, default: "normal"
    add_column :libraries, :user_id, :bigint, null: true

    add_index :libraries, :role
    add_index :libraries, :user_id
    add_index :libraries, [:role, :user_id], unique: true, where: "role = 'scanned_list'"

    add_foreign_key :libraries, :users, on_delete: :nullify
  end
end
```

**Model Updates:**
```ruby
# app/models/library.rb
class Library < ApplicationRecord
  belongs_to :user, optional: true

  enum :role, {
    normal: "normal",
    scanned_list: "scanned_list"
  }

  validates :role, uniqueness: { scope: :user_id }, if: -> { scanned_list? }

  def scanned_list?
    role == "scanned_list"
  end
end
```

---

### 1.3 Add LibraryItem Nature

**Migration:**
```ruby
# db/migrate/XXXXXX_add_nature_to_library_items.rb
class AddNatureToLibraryItems < ActiveRecord::Migration[8.0]
  def change
    add_column :library_items, :nature, :string, default: "physical"

    # Existing items are assumed to be physical
    LibraryItem.update_all(nature: "physical")

    add_index :library_items, :nature
  end
end
```

**Model Updates:**
```ruby
# app/models/library_item.rb
class LibraryItem < ApplicationRecord
  enum :nature, {
    physical: "physical",
    virtual: "virtual"
  }

  # Virtual items only need notes
  # Physical items have all the acquisition/condition fields
  validates :acquisition_date, presence: true, if: :physical?
  validates :condition, presence: true, if: :physical?

  def physical?
    nature == "physical"
  end

  def virtual?
    nature == "virtual"
  end
end
```

---

### 1.4 Add Attribution Tracking

**Migration:**
```ruby
# db/migrate/XXXXXX_add_attribution_to_library_items.rb
class AddAttributionToLibraryItems < ActiveRecord::Migration[8.0]
  def change
    add_column :library_items, :added_by_id, :bigint, null: true
    add_column :library_items, :updated_by_id, :bigint, null: true

    add_foreign_key :library_items, :users, column: :added_by_id, on_delete: :nullify
    add_foreign_key :library_items, :users, column: :updated_by_id, on_delete: :nullify

    add_index :library_items, :added_by_id
    add_index :library_items, :updated_by_id
  end
end
```

**Model Updates:**
```ruby
# app/models/library_item.rb
class LibraryItem < ApplicationRecord
  belongs_to :added_by, class_name: "User", optional: true
  belongs_to :updated_by, class_name: "User", optional: true

  before_create :set_added_by
  before_update :set_updated_by

  private

  def set_added_by
    self.added_by_id = Current.user.id if Current.user
  end

  def set_updated_by
    self.updated_by_id = Current.user.id if Current.user
  end
end
```

---

### 1.5 Add User Admin Role

**Migration:**
```ruby
# db/migrate/XXXXXX_add_role_to_users.rb
class AddRoleToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :role, :string, default: "member"

    # First user is admin
    if User.any?
      User.order(:created_at).first.update(role: "admin")
    end

    add_index :users, :role
  end
end
```

**Model Updates:**
```ruby
# app/models/user.rb
class User < ApplicationRecord
  enum :role, {
    member: "member",
    admin: "admin"
  }

  def admin?
    role == "admin"
  end

  def member?
    role == "member"
  end

  # Prevent first admin from being demoted
  before_update :protect_first_admin, if: -> { role_changed? && role_was == "admin" }

  private

  def protect_first_admin
    if id == User.order(:created_at).first.id
      errors.add(:role, "cannot be changed for the first admin")
      throw(:abort)
    end
  end
end
```

---

### 1.6 Add Scanned List Helper to User

**Model Updates:**
```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_many :libraries

  def scanned_list
    libraries.find_or_create_by!(role: :scanned_list) do |lib|
      lib.name = "#{username}'s scans"
      lib.description = "My scan inbox"
      lib.user = self
    end
  end
end
```

---

## Phase 2: Controller Updates

### 2.1 Update ScannersController

**Changes needed:**
```ruby
# app/controllers/scanners_controller.rb
class ScannersController < ApplicationController
  def index
    # Current user's scanned list is default target
    @default_library = current_user.scanned_list
    @libraries = Library.all.order(:name)
  end
end
```

**Scanner view updates:**
- Add library selection dropdown
- Add nature toggle (Physical/Virtual)
- Default to user's scanned list
- Default to physical nature

---

### 2.2 Update ProductsController

**When scanning/add to library:**
```ruby
# app/controllers/products_controller.rb
def show
  @product = Product.find_or_create_by!(gtin: params[:ean13])

  # If user came from scanner, add to their scanned list
  if params[:from_scanner]
    library = current_user.scanned_list
    nature = params[:nature] || "physical"

    @library_item = LibraryItem.create!(
      library: library,
      product: @product,
      nature: nature,
      added_by: current_user
    )
  end
end
```

---

### 2.3 Update LibrariesController

**Move items between libraries:**
```ruby
# app/controllers/libraries_controller.rb
def move_items
  @library = Library.find(params[:id])
  @target_library = Library.find(params[:target_library_id])
  @items = LibraryItem.where(id: params[:item_ids])

  @items.update_all(library_id: @target_library.id)

  redirect_to @library, notice: "Moved #{@items.count} items"
end
```

**Bulk operations:**
- Move selected items
- Change nature of selected items
- Delete selected items

---

### 2.4 Update LibraryItemsController

**Form updates:**
- Add nature selection (Physical/Virtual)
- Show/hide fields based on nature
- Physical: acquisition, condition, location
- Virtual: notes only

**Controller updates:**
```ruby
# app/controllers/library_items_controller.rb
def create
  @library_item = LibraryItem.new(library_item_params)
  @library_item.added_by = current_user

  if @library_item.save
    redirect_to @library_item.library, notice: "Item added"
  else
    render :new
  end
end

def update
  @library_item = LibraryItem.find(params[:id])
  @library_item.updated_by = current_user

  if @library_item.update(library_item_params)
    redirect_to @library_item.library, notice: "Item updated"
  else
    render :edit
  end
end
```

**Strong parameters:**
```ruby
def library_item_params
  params.require(:library_item).permit(
    :nature,
    :acquisition_date,
    :acquisition_source,
    :acquisition_price,
    :condition,
    :condition_notes,
    :location,
    :notes,
    # ... other physical item fields
  )
end
```

---

### 2.5 Update UserController

**Add user management:**
```ruby
# app/controllers/user_controller.rb
before_action :require_admin, only: [:new, :create, :destroy, :update_role]

def index
  @users = User.all
end

def new
  @user = User.new
end

def create
  @user = User.new(user_params)

  if @user.save
    redirect_to users_path, notice: "User invited"
  else
    render :new
  end
end

def update_role
  @user = User.find(params[:id])
  @user.update!(role: params[:role])
  redirect_to users_path, notice: "User role updated"
end

private

def require_admin
  unless current_user&.admin?
    redirect_to root_path, alert: "Admin only"
  end
end
```

---

## Phase 3: View Component Updates

### 3.1 Update Navigation

**Remove "My Scans" button:**
- Remove from `Components::Shared::NavigationView`
- Add link to user's scanned list if needed

**Add "Libraries" link:**
- Browse all libraries on instance

---

### 3.2 Update Library Views

**`Components::Libraries::ShowView`:**
- Show library role badge (if scanned_list)
- Show library description
- List all LibraryItems with nature badges
- Show "added by" attribution
- Add bulk action controls (select, move, delete)

**Nature badges:**
```
[Physical] - green badge for physical items
[Want] - blue badge for virtual items
```

**Attribution display:**
```
Added by Pete 2 days ago
```

---

### 3.3 Update Scanner View

**`Components::Scanners::IndexView`:**
- Library selection dropdown (default: scanned list)
- Nature toggle (Physical/Virtual)
- Recent scans preview (last 10 items from scanned list)
- Clean, minimal UI for rapid scanning

---

### 3.4 Update LibraryItem Forms

**`Components::LibraryItems::EditView`:**
- Nature selector at top
- Show/hide fields based on nature
- Physical: full form with acquisition, condition
- Virtual: simplified form with notes only

**JavaScript for dynamic form:**
```javascript
// Toggle fields based on nature
document.addEventListener('change', (e) => {
  if (e.target.name === 'library_item[nature]') {
    const nature = e.target.value;
    // Show/hide physical vs virtual fields
  }
});
```

---

### 3.5 Update Product Views

**`Components::Products::ShowView`:**
- Show product details
- Show all LibraryItems across all libraries
- "Add to my scanned list" button
- Nature selection when adding

---

## Phase 4: Sharing System

### 4.1 Create SharedLink Model

**Migration:**
```ruby
# db/migrate/XXXXXX_create_shared_links.rb
class CreateSharedLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :shared_links do |t|
      t.string :token, null: false, index: { unique: true }
      t.references :shareable, polymorphic: true, null: false, index: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.timestamps

      t.index [:shareable_type, :shareable_id, :token]
    end
  end
end
```

**Model:**
```ruby
# app/models/shared_link.rb
class SharedLink < ApplicationRecord
  belongs_to :shareable, polymorphic: true
  belongs_to :created_by, class_name: "User"

  validates :token, presence: true, uniqueness: true

  before_create :generate_token

  private

  def generate_token
    self.token = SecureRandom.hex(16)
  end
end
```

---

### 4.2 Add Sharing to Libraries

**Model:**
```ruby
# app/models/library.rb
class Library < ApplicationRecord
  has_many :shared_links, as: :shareable, dependent: :destroy

  def create_shared_link!(user)
    shared_links.create!(created_by: user)
  end

  def public_share_token
    shared_links.last&.token
  end
end
```

---

### 4.3 Create Sharing Controller

```ruby
# app/controllers/shares_controller.rb
class SharesController < ApplicationController
  before_action :set_shareable

  def show
    # Render public read-only view
    # HTML: /share/:token
    # JSON: /share/:token.json
  end

  private

  def set_shareable
    @shared_link = SharedLink.find_by!(token: params[:token])
    @library = @shared_link.shareable
  end
end
```

---

### 4.4 Add Sharing UI

**Library show view:**
- "Share" button → generates token
- Display share URL: `https://instance.com/share/TOKEN`
- "Copy link" button
- "Delete link" button (revokes access)

---

## Phase 5: Clean Up

### 5.1 Hide Loan/Circulation Fields

**In LibraryItem forms:**
- Hide: `lent_to`, `due_date`, `status` (checked_out, etc.)
- Keep in database for Phase 2
- Don't display in UI

**CSS/Tailwind:**
- Add `.hidden` class to these fields
- Or remove from form entirely

---

### 5.2 Update Navigation

**Remove:**
- "My Scans" button/link

**Add:**
- "Libraries" link (browse all)
- "Users" link (admin only)

---

### 5.3 Update Routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  root "products#index"
  resources :products, only: [:index, :show]
  resources :libraries, only: [:index, :show]
  resources :library_items, only: [:new, :create, :edit, :update, :destroy]
  resources :users, only: [:index, :new, :create, :edit, :update]

  # Scanner
  get "/scanner", to: "scanners#index"

  # Sharing
  get "/share/:token", to: "shares#show", as: :shared_library

  # Health check
  get "/up", to: "rails/health#show"
end
```

---

## Implementation Order

### Step 1: Database & Models (1-2 hours)
1. Run all migrations
2. Update model files
3. Test in Rails console

### Step 2: Controllers (2-3 hours)
1. Update ScannersController
2. Update ProductsController
3. Update LibrariesController
4. Update LibraryItemsController
5. Add UserController methods

### Step 3: View Components (3-4 hours)
1. Update Scanner view
2. Update Library views
3. Update Product views
4. Update forms
5. Update navigation

### Step 4: Sharing System (2-3 hours)
1. Create SharedLink model
2. Add sharing to Libraries
3. Create SharesController
4. Add sharing UI

### Step 5: Testing & Polish (2-3 hours)
1. Test all workflows
2. Fix bugs
3. Polish UI
4. Add error handling

**Total Estimate: 10-15 hours**

---

## Checklist

### Database
- [ ] Drop scans table
- [ ] Add role to libraries
- [ ] Add user_id to libraries
- [ ] Add nature to library_items
- [ ] Add attribution to library_items
- [ ] Add role to users

### Models
- [ ] Update Library model
- [ ] Update LibraryItem model
- [ ] Update User model
- [ ] Create SharedLink model
- [ ] Remove Scan model

### Controllers
- [ ] Update ScannersController
- [ ] Update ProductsController
- [ ] Update LibrariesController
- [ ] Update LibraryItemsController
- [ ] Update UserController
- [ ] Create SharesController

### Views
- [ ] Update Scanner view
- [ ] Update Library show view
- [ ] Update Product views
- [ ] Update LibraryItem forms
- [ ] Update Navigation

### Routes
- [ ] Remove scans routes
- [ ] Add sharing routes
- [ ] Update navigation links

### Testing
- [ ] Test scanning workflow
- [ ] Test moving items between libraries
- [ ] Test physical vs virtual items
- [ ] Test sharing links
- [ ] Test admin/user management
