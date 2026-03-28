# Shelflife App

A comprehensive description of each page and feature in Shelflife.

## Core Concept

Shelflife helps you manage physical collections of books, games, DVDs, and other barcode-scannable items. The app distinguishes between:

- **Products**: Bibliographic data about a work/edition (identified by EAN-13 barcode)
- **Library Items**: Physical copies of products that belong to specific libraries
- **Libraries**: Collections that organize library items (shared between all users)
- **Scans**: User-specific history of barcode scans

Each product can have multiple library items across different libraries (if you own multiple copies).

## Authentication & User Management

### Login (`/signin`)
Email/password login with session management. Required for most features.

### Signup (`/signup`)
New user registration with email and password.

### User Profile (`/profile`)
Shows user information, TBDB (The Book Database) connection status, and preferences.

### Edit Profile (`/profile/edit`)
Update user information and manage account settings.

### Change Password (`/profile/change_password`)
Secure password change functionality.

## Main Navigation

### Fixed Header Navigation
- Brand "ShelfLife" on the left
- Contextual navigation links (Scan, Libraries, My Scans, Profile)
- Prominent "Scan" button for quick access
- Responsive design with mobile optimization

## Dashboard (`/)
**Landing page after login**
- Statistics: Total products, library items, scans
- Quick access to recent scans and libraries
- Navigation cards for main features
- Shows recently scanned products across all libraries

## Barcode Scanning

### Adaptive Scanner (`/scanner`)
Full-featured camera-based barcode scanner:
- Portrait and landscape optimized layouts
- Library selection dropdown (auto-assign scanned items)
- Recent scans display (last 10 scans)
- Real-time camera feed with EAN-13 validation
- Automatic product creation/enrichment from TBDB

### Horizontal Scanner (`/scanner/horizontal`)
Alternative scanning interface optimized for landscape mode:
- Streamlined UI for rapid scanning
- Single-scan mode (jumps directly to product)
- Scan-to-library mode with dropdown selection

## My Scans (`/scans`)
Personal scan history for the current user:
- Chronological list of all scanned barcodes
- Product links and scan timestamps
- Delete individual scans
- Pagination for large scan histories

## Product Management

### Product Details (`/:gtin` or `/products/:id`)
Comprehensive product information display:
- Cover image and basic metadata (title, author, publisher)
- TBDB-enriched data (format, language, region, players, age range)
- All library items across all libraries
- Refresh product data from TBDB
- Delete product (removes all associated scans and library items)

**Note**: Products are created automatically through barcode scanning or manual GTIN entry. No direct manual product creation form exists.

## Libraries

### Libraries Index (`/libraries`)
List of all libraries in the system:
- Library cards with names and descriptions
- Sample items from each library (randomly selected)
- Create new library button
- Search and filter functionality

### Library Details (`/libraries/:id`)
Detailed view of a single library:
- Paginated list of library items grouped by product
- Library statistics and metadata
- Edit library button
- Export library data (CSV)
- Import items button

### Edit Library (`/libraries/:id/edit`)
Update library information:
- Name, description, location
- Public/private visibility settings
- Bulk barcode import (manual GTIN entry)

### Library Import (`/libraries/:id/import`)
Bulk addition of items via CSV file upload:
- Supports GTIN-13 barcodes
- Creates products and library items automatically
- Error handling and validation reporting

### Library Export (`/libraries/:id/export`)
Download library data as CSV:
- All library items with full metadata
- Condition, acquisition, and status information
- Compatible with import system

## Library Items

### Library Item Details (`/library_items/:id`)
Comprehensive information about a physical copy:
- Product information (cover, title, author, etc.)
- Physical condition details and photos
- Acquisition information (purchase date, price, source)
- Current location and ownership status
- Lending status (if applicable)
- Value tracking and private notes

### Edit Library Item (`/library_items/:id/edit`)
Extensive item management options:
- **Condition Tracking**: Condition grade, notes, damage description
- **Acquisition Details**: Purchase date, price, source, copy identifier
- **Status Management**: Available, checked out, missing, damaged, etc.
- **Location**: Storage location within library
- **Ownership**: Owned, borrowed, on loan, consignment
- **Value Tracking**: Replacement cost, original retail price, market value
- **Lending**: Lent to person, due date (currently hidden in UI)
- **Metadata**: Tags, favorite status, private notes

## Lending Features (Currently Hidden)

The application includes comprehensive lending functionality that is built but not exposed in the current UI:

- **Checkout/Checkin System**: Built into LibraryItem model
- **Lending Status Tracking**: lent_to and due_date fields
- **Overdue Detection**: Automatic detection with scopes
- **Status Management**: Item status enum for circulation tracking

*Note: These features exist in the data model and can be enabled when needed.*

## Advanced Features

### TBDB Integration
- OAuth connection to The Book Database
- Automatic product data enrichment
- Manual refresh of product data
- Connection status monitoring in user profile

### Background Processing
- Solid Queue for background jobs
- Automatic data fetching and enrichment
- Real-time UI updates via Turbo streams

### Import/Export System
- CSV-based library data management
- Bulk barcode import via manual entry
- Error handling and validation
- Data portability between libraries

## Mobile Responsiveness

All pages are optimized for mobile devices:
- Responsive layouts with Tailwind CSS
- Touch-friendly interfaces
- Adaptive scanner layouts
- Collapsible navigation on mobile
- Landscape/h orientation support

