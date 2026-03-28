# ShelfLife: Codebase Reset & Alignment

## Context for Claude Code

ShelfLife is a Rails app (SQLite) for cataloguing personal collections — books, board games, DVDs, whisky, vinyl, etc. It uses barcode scanning via the web to add items. Product data comes from TheBookDB (TBDB) API, which is a separate system built into Booko (also Rails, same owner).

This document is the **single source of truth** for what ShelfLife should be. CLAUDE.md should be updated to reflect this document.

## Product Vision

### What ShelfLife Is
A personal/small-group library app. You scan things you collect, and ShelfLife tracks them. It's for people who own more stuff than they can keep in their head — the person standing in an op shop wondering "do I already own this?"

### What ShelfLife Is Not (Yet)
- Not a social network
- Not a recommendation engine
- Not a marketplace
- Not a lending platform

### The Two Core Actions
1. **Scan something you have** → it goes into your library, marked as "have"
2. **Scan something you want** → it goes into your library, marked as "want"

Libraries are containers. The have/want distinction lives on the item, not the library.

That's the MVP. Everything else is secondary.

### Relationship to TBDB / Booko
- ShelfLife gets product data from TBDB's API (title, author, cover, ISBN, etc.)
- ShelfLife does NOT have its own product editing UI yet — but it will. Users should be able to correct product data without leaving the app.
- Corrections made in ShelfLife will eventually flow back to TBDB (opt-in, upstream push). For now, capture corrections locally.
- ShelfLife links out to Booko for pricing data — "see prices on Booko". This is a Booko revenue stream, not a ShelfLife one.
- ShelfLife is a **consumer** of TBDB data. TBDB is a separate system with separate ownership.

## Data Model

### User
- `name`, `email_address`, `admin` (boolean)
- Authentication via whatever is currently implemented (keep it simple)

### Library
- A container for organising items. Think "shelves" — Home, Work, Mum's House, etc.
- Belongs to User (optional)
- `name` (string), `description` (string)
- `visibility` (enum): `ours` (private, default), `anyone` (shareable via link), `everyone` (public/discoverable)
- No special roles — a library is just a named container

### Product
- The canonical product record, populated from TBDB
- `title`, `image_url`, `tbdb_id`, `gtin` (EAN-13), etc.
- Products are shared across all users (if two people scan the same ISBN, they reference the same Product)

### LibraryItem
- The join between Library and Product — "this user has this product in this library"
- Belongs to Library, belongs to Product
- `intent` (integer enum): `have` (0, default), `want` (1)
- Tracking: `added_by` / `updated_by` (User FKs), `date_added`
- Condition: `condition` (FK), `condition_notes`
- Acquisition: `acquisition_date`, `acquisition_source` (FK), `acquisition_price`
- Status: `item_status` (FK), `ownership_status` (FK)
- Misc: `location`, `tags`, `is_favorite`, `notes`, `private_notes`

### Lookup tables (seeded)
`Condition`, `ItemStatus`, `OwnershipStatus`, `AcquisitionSource` — all populated by `db:seed`.

## Core User Flows

### Flow 1: Scan and Have
1. User opens scanner (web-based camera barcode scanner)
2. Barcode detected → hit TBDB API with barcode
3. Product found → show product details (cover, title, author/publisher)
4. User taps "Add to Library" → LibraryItem created with intent: `have`
5. If product NOT found in TBDB → show "Product not found" with option to add manually

### Flow 2: Scan and Want
1. Same scan flow as above
2. User taps "Want" → LibraryItem created with intent: `want`
3. Want items are candidates for Booko price alert integration (future)

### Flow 3: Browse Library
1. User sees their library — grid or list view of covers/titles
2. Filter by have/want, search within library
3. Tap an item → see details, edit notes, change intent, remove

### Flow 4: Manual Add (No Barcode)
1. User searches by title/author
2. TBDB search results shown
3. User picks the right product → adds to library as have or want

## What to Clean Up in the Codebase

### Priority 1: Align schema with reality
- Audit every model file against the actual database schema
- Remove references to fields that don't exist
- Make sure CLAUDE.md accurately describes what's in the schema RIGHT NOW

### Priority 2: Libraries are containers, items carry intent
- Remove `scanned_list`, `list`, `subscription` role concepts from Library
- LibraryItem has `intent` enum: `have` (0), `want` (1)
- Scanner UI picks library + intent
- "My wants" = filter items by intent across any library

### Priority 3: Remove lending/sharing confusion
- Remove any lending-related code, routes, views
- Remove SharedLink if it exists
- The only "sharing" concept is `visibility` on Library, and it doesn't need UI yet

### Priority 4: Scanner health check
- Verify the web barcode scanner still works
- Verify the TBDB API integration works (scan → lookup → display product)
- Fix any broken flows in the scan-to-add pipeline
- This is the critical path — if scanning doesn't work smoothly, nothing else matters

### Priority 5: Product editing (stub only)
- Don't build a full editing UI yet
- Add a "Suggest Correction" link/button on the product detail page
- For now this can link to the product on TBDB, or open a minimal form that stores the suggestion locally

## What NOT to Do

- Don't add authentication complexity (OAuth, SSO, JWT tokens)
- Don't build subscription/sharing features. Post-MVP.
- Don't build payment/billing integration
- Don't optimise for multi-tenant hosting. Single instance is fine.
- Don't build an API for the iOS app yet
- Don't refactor the data model beyond what's described here

## Definition of Done

When this cleanup is complete, the app should:

1. Let a new user sign up and have a default library
2. Let them scan a barcode via the web scanner and see the product from TBDB
3. Let them add that product as "have" or "want" with one tap
4. Let them browse their library, filtering by have/want
5. Let them manually search and add products without scanning
6. Have clean, accurate documentation (CLAUDE.md) that matches the actual codebase
7. Have no dead code related to lending, SharedLink, scanned_list roles, or unimplemented features
8. Have a "Suggest Correction" stub on product pages

That's it. No more, no less. Ship this, then we test it with real people.

## Technical Notes

- Rails app, SQLite database
- Web-based barcode scanner (phone camera via browser)
- TBDB API for product data (read-only for now)
- Keep it deployable as a single process (Puma)
