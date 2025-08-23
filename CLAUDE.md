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

### Development Notes
- Uses Rails 8's new defaults with Solid adapters for caching, queuing, and cables
- **Phlex 2 components** replace traditional ERB views - use `plain` for mixed text/HTML content
- Stimulus controllers handle all JavaScript interactions
- esbuild handles JavaScript bundling, Tailwind 4 handles CSS compilation
- SQLite for development and testing (multiple databases for different Rails features)
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
