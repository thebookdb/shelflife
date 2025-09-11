# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Rails Application
- `bin/rails server` - Start the development server
- `bin/rails console` - Open Rails console
- `bin/rails test` - Run the test suite
- `bin/rails generate` - Generate Rails files
- `bin/rails db:migrate` - Run database migrations
- `bin/rails db:seed` - Seed the database

### Asset Pipeline
- `npm run build` - Build JavaScript with esbuild (outputs to app/assets/builds/)
- `npm run build:css` - Build CSS with Tailwind (outputs to app/assets/builds/application.css)
- `bin/rails assets:precompile` - Precompile all assets for production

### Code Quality
- `bundle exec rubocop` - Run Ruby linter (omakase style)
- `bundle exec brakeman` - Run security analysis

### Development Process
- `overmind start -f Procfile.dev` or `foreman start -f Procfile.dev` - Start all development services

## Architecture Overview

This is a Rails 8.0 application focused on barcode scanning for various products including books, board games, DVDs, CDs, and other items with EAN-13 barcodes.

### Key Technologies
- **Backend**: Rails 8.0 with Phlex for view components
- **Frontend**: Stimulus controllers with Turbo for SPA-like experience
- **Styling**: Tailwind CSS with cssbundling-rails
- **JavaScript**: esbuild bundling with jsbundling-rails
- **Database**: SQLite with Solid adapters (solid_cache, solid_queue, solid_cable)
- **Barcode Scanning**: html5-qrcode library for camera-based scanning
- Use Phlex 2 and Tailwind 2 

### Application Structure

#### Controllers
- `ProductsController` - Handles product display and library management
  - `index` action shows recent scanned products with navigation
  - `show` action displays individual product details
  - Uses Phlex view components instead of ERB templates
  - EAN-13 route constraint: `/:ean13` matches exactly 13 digits
- `ScannersController` - Dedicated barcode scanning interface
  - `index` action provides full-screen scanner interface
  - Manages library selection for scanned items
  - Displays recent scans for user context

#### View Components (Phlex)
- `Components::Products::IndexView` - Dashboard showing recent additions with navigation
- `Components::Products::ShowView` - Individual product detail page
- `Components::Scanners::IndexView` - Dedicated barcode scanner interface
- `Components::Shared::NavigationView` - Site-wide navigation with primary "Scan" button
- All views inherit from `Phlex::HTML` for component-based templates

#### JavaScript (Stimulus)
- `barcode_scanner_controller.js` - Main barcode scanning functionality
  - Uses html5-qrcode library for camera access
  - Validates EAN-13 format (13 digits)
  - Automatically redirects to `/:ean13` on successful scan
  - Handles camera permissions and scanner lifecycle

#### Routing
- Root route `/` → Products index (dashboard with recent additions)
- Scanner route `/scanner` → Dedicated scanning interface
- Scans route `/scans` → User's scan history ("My Scans")
- Dynamic route `/:ean13` → Product show (13-digit constraint)
- Health check at `/up`

### Key Features
- **Separated User Interface**: Dashboard (/) for recent additions, dedicated scanner (/scanner)
- **Camera-based barcode scanning** with html5-qrcode library
- **EAN-13 barcode format** validation and detection
- **Mobile-responsive design** with Tailwind CSS and optimized touch interfaces
- **Component-based view architecture** with Phlex 2
- **User-scoped scan history** - "My Scans" functionality
- **Site-wide navigation** with prominent "Scan" button for quick access
- **Recent additions dashboard** showing user's recently scanned products
- Modern Rails 8 features with Solid adapters

### Navigation Flow
- **Home Dashboard (/)**: Shows recent scanned products, "Scan" and "My Scans" buttons
- **Scanner (/scanner)**: Full-screen scanning interface with library selection
- **My Scans (/scans)**: Complete scan history for the current user
- **Product Details (/:ean13)**: Individual product pages linked from recent additions
- **Site Navigation**: Fixed header with prominent "Scan" button (primary color) for quick access

## Data Models

### Core Models

#### Product (Bibliographic Data)
Represents the published work/edition scanned from a barcode:
- `gtin` - EAN-13 barcode (primary identifier)
- Basic metadata: `title`, `subtitle`, `author`, `publisher`, `publication_date`, `description`
- Format data extracted from TBDB API: `notes` (format, language, region), `players`, `age_range`
- Media type: `product_type` (book, dvd, board_game)
- Enrichment: `tbdb_data` JSON field with API response data
- **Auto-enrichment**: ProductEnrichmentService extracts format-specific data during creation

#### LibraryItem (Physical Copy Tracking)
Represents a specific physical copy of a Product in a Library:
- **Acquisition**: `acquisition_date`, `acquisition_source`, `acquisition_price`, `copy_identifier`
- **Condition**: `condition`, `condition_notes`, `last_condition_check`, `damage_description`
- **Status**: `status` enum (available, checked_out, missing, damaged, in_repair, retired)
- **Ownership**: `ownership_status` enum (owned, borrowed, on_loan, consignment)
- **Location**: `location`, `library_id` (always belongs to a library)
- **Circulation**: `lent_to`, `due_date` (for future checkout system)
- **Value**: `replacement_cost`, `original_retail_price`, `current_market_value`
- **Metadata**: `private_notes`, `tags`, `last_accessed`, `is_favorite`

#### Library
Collections that organize LibraryItems:
- `name`, `description`
- Communal between all users (shared collections)

#### Scan
User-specific tracking of barcode scans:
- Links to Product and User for scan history
- `scanned_at` timestamp for "My Scans" functionality

### Development Notes
- Uses Rails 8's new defaults with Solid adapters for caching, queuing, and cables
- **Phlex 2 components** replace traditional ERB views - use `plain` for mixed text/HTML content
- Stimulus controllers handle all JavaScript interactions
- esbuild handles JavaScript bundling, Tailwind 4 handles CSS compilation
- SQLite for development and testing (multiple databases for different Rails features)
- **Data Separation**: Product = bibliographic data, LibraryItem = physical copy tracking
- **Auto-enrichment**: TBDB API data automatically populates format fields during product creation
- **ULID Primary Keys**: All models use ULID strings as primary keys (not integers)
- **Foreign Keys**: All foreign key references are strings pointing to ULID primary keys
- **Book Identification**: Books identified by EAN-13 barcodes (13-digit strings)
- **Image Handling**: Products have `cover_image` (Active Storage) and `cover_image_url` fields
- Pagination handled by Pagy gem
- the MCP gitea is available for the repository dkam/shelf-life for git actions

### Development Warnings
- Libraries are communal between all users
- Scans belong to users
- **Phlex 2 Syntax**: Use `plain "text"` for text content when mixing with HTML elements


---

# Development Roadmap

## Vision
A self-hosted, open-source home library management system for books, board games, and DVDs with unique social discovery features.

## Phase 1: Personal Collection Management ✅ **(CURRENT)**

### Completed Features ✅
- **Barcode Scanning**: Phone camera scanning with auto-population from TBDB API
- **Enhanced Data Models**: Complete Product/LibraryItem separation with comprehensive tracking
- **Multi-Media Support**: Books, board games, DVDs with format-specific data extraction
- **Individual Copy Tracking**: UUID support, condition tracking, acquisition data, value tracking
- **Advanced Status Management**: Enums for status, ownership, acquisition source
- **Auto-enrichment**: TBDB API data automatically populates format, language, duration fields

### Current Implementation
```ruby
# ✅ IMPLEMENTED
class Product  # Bibliographic data from barcode
  # gtin, title, author, publisher, product_type
  # notes (extracted format data), players, age_range
  # tbdb_data with auto-enrichment
end

class LibraryItem  # Physical copy tracking  
  belongs_to :product, :library
  # acquisition_date, acquisition_source, acquisition_price
  # condition tracking, status enum, ownership_status
  # value tracking, tags, favorites, circulation fields
end

class Library  # Collections (communal)
  # name, description
end

class Scan  # User scan history
  belongs_to :product, :user
end
```

### Remaining MVP Tasks
- **Enhanced UI**: Views for new LibraryItem fields (acquisition, condition, value)
- **Search & Filtering**: By condition, status, tags, library
- **Bulk Operations**: Condition updates, library transfers
- **QR Code Generation**: For individual copies using copy_identifier

### Monetization
- Free self-hosted open source
- TBDB API: Free tier (100 lookups/month)

## Phase 2: Social Discovery & Library Linking

### Unique Features
- **Library Subscriptions**: Subscribe to friends' libraries to see their collections
- **Little Free Library Integration**: Live inventory updates for nearby community libraries
- **Privacy Controls**: Granular sharing (reading lists vs. expensive items)
- **Wishlist Matching**: Notifications when subscribed libraries get items you want
- **Discovery Features**: Browse collections by person, location, or topic

### Enhanced Data Model
```ruby
class Library
  # Add: public, shareable, library_type (personal/little_free/community)
end

class Subscription
  belongs_to :user
  belongs_to :library
  # privacy_level, notification_preferences
end

class Wishlist
  belongs_to :user
  belongs_to :product
end
```

### Monetization
- Hosted convenience plans: $20-50/year
- Premium social features: $50/year for library linking, advanced notifications
- ThebookDB API tiers: Hobby ($5/month), Commercial ($20/month)
- Little Library stewards: Free (builds network effect)

## Phase 3: Checkout & Circulation

### Advanced Features
- **Cross-Library Checkout**: Borrow from friends' collections through the app
- **Little Library Holds**: Reserve items at community libraries
- **Circulation Management**: Due dates, overdue notifications, return tracking
- **Borrowing History**: Track lending relationships and reading habits
- **Automated Notifications**: Email/SMS for due dates, new arrivals, holds available

### Additional Models
```ruby
class CheckoutTransaction
  belongs_to :library_item
  belongs_to :borrower, class_name: 'User'
  belongs_to :lender, class_name: 'User'
  # checkout_date, due_date, returned_date, status
end

class Hold
  belongs_to :user
  belongs_to :library_item
  # requested_date, available_date, expires_at
end
```

### Advanced Monetization
- Premium circulation features for power users
- Community/organization plans for groups of Little Libraries
- Analytics and reporting features

## Technical Considerations

### MVP Simplicity
- Start with basic Product → LibraryItem → Library relationships
- Add Series/Work/Universe complexity later as needed
- Focus on core scanning and inventory workflow first

### Competitive Advantages
1. **Data Moat**: ThebookDB integration for comprehensive metadata
2. **Social Discovery**: Library linking feature unavailable elsewhere  
3. **Little Free Library Focus**: Underserved community with specific needs
4. **Cross-Media Support**: Books, games, DVDs in single system

### Development Priorities
1. **Phase 1**: Nail the basic home library experience
2. **Phase 2**: Build network effects through social features  
3. **Phase 3**: Add circulation for complete library management

## Success Metrics
- **MVP**: Active personal libraries, API usage, self-hosting adoption
- **Phase 2**: Library subscriptions, social engagement, Little Library partnerships
- **Phase 3**: Checkout transactions, community growth, premium conversions