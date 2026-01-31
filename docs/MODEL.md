# ShelfLife Data Model

## Overview

ShelfLife is a single-tenant Rails application for cataloging and sharing collections of products identified by EAN-13 barcodes. The app supports any product type available in TBDB (The Book Database), including books, board games, DVDs, CDs, vinyl records, whisky, and other consumer goods.

## Core Concepts

### Product (Bibliographic Data)
A `Product` represents published work/edition information from TBDB. It is the canonical bibliographic record for a barcode.

**Attributes:**
- `gtin` - EAN-13 barcode (primary identifier)
- `title`, `subtitle`, `author`, `publisher`, `publication_date`
- `description` - Product summary
- `notes` - Format details extracted from TBDB (format, language, region)
- `players`, `age_range` - For games/media
- `product_type` - Media category (book, dvd, board_game, etc.)
- `tbdb_data` - Full JSON response from TBDB API
- `cover_image` - Active Storage attachment
- `cover_image_url` - URL from TBDB

**Key Point:** Products are NOT user-specific. All users on an instance share the same Product records. If you and I both scan the same barcode, we reference the same Product.

---

### Library (Collection)
A `Library` is a collection of items owned collectively by all users on the instance.

**Attributes:**
- `name` - Display name (e.g., "Study", "Board Games", "Wishlist")
- `description` - Free text notes about location or content
- `role` - Either `normal` or `scanned_list`
- `user_id` - Owner (only set for `scanned_list` libraries)

**Library Types:**

| Type | Purpose | Ownership | Visibility |
|------|---------|-----------|------------|
| `normal` | General collections | Communal (user_id = nil) | All users on instance |
| `scanned_list` | User's scan inbox | Owned by specific user | All users on instance |

**Key Behaviors:**
- All users on an instance can see and use all libraries
- Each user has ONE `scanned_list` library (auto-created on first scan)
- Normal libraries are communal - no owner, shared by all users
- Libraries are flexible - users organize them however they want (by location, type, purpose, etc.)

---

### LibraryItem (Item in a Collection)
A `LibraryItem` represents a product's presence in a library. It is the join between Products and Libraries, with additional metadata about ownership and physical state.

**Attributes:**

**Core:**
- `library_id` - Which library contains this item
- `product_id` - Which product this references
- `nature` - Either `physical` or `virtual`
- `added_by_id` - User who created this record
- `updated_by_id` - User who last modified this record

**Physical Item Attributes (only when nature = physical):**
- `acquisition_date` - When acquired
- `acquisition_source` - Where/from whom (e.g., "Amazon", "Gift from Mom")
- `acquisition_price` - Purchase price
- `copy_identifier` - Distinguishes multiple copies (e.g., "Reading copy", "Collector's edition")
- `condition` - Physical state (mint, good, worn, damaged)
- `condition_notes` - Specific condition details
- `last_condition_check` - Last inspection date
- `damage_description` - Damage documentation
- `ownership_status` - owned, borrowed, on_loan, consignment
- `location` - Physical location within library
- `lent_to`, `due_date` - Circulation tracking (hidden in Phase 1)
- `replacement_cost`, `original_retail_price`, `current_market_value` - Valuation
- `private_notes` - Personal notes (hidden from public views)
- `tags` - Flexible categorization
- `is_favorite` - Bookmarking

**Virtual Item Attributes (only when nature = virtual):**
- `notes` - Purpose or context (e.g., "Want first edition with dust jacket")

**Item Nature:**

| Nature | Meaning | Physical Attributes | Use Case |
|--------|---------|---------------------|----------|
| `physical` | I own this copy | All acquisition/condition fields | Cataloging owned items |
| `virtual` | I want this or am tracking it | Only notes field | Wishlists, to-read lists, reference collections |

**Key Behaviors:**
- Multiple LibraryItems can exist for the same Product (e.g., 2 copies of same book)
- Virtual items are for things you DON'T have but want to track
- Physical items represent actual ownership
- All users can add/edit/delete any LibraryItem (full permissions within instance)

---

### User (Instance Member)
A `User` represents a person with access to the ShelfLife instance.

**Attributes:**
- `username`, `email` - Identity
- `role` - Either `admin` or `member`

**User Roles:**

| Role | Permissions |
|------|-------------|
| `admin` | Full access + user management + admin designation |
| `member` | Full access to all libraries and items |
| `first admin` | Cannot be removed from admin role (account creator) |

**Key Behaviors:**
- All users have full access to all libraries and items (no read-only users)
- Only admins can invite/remove users and grant admin privileges
- First admin is permanent (cannot demote themselves)
- Each user has their own `scanned_list` library for scan inbox

---

## Relationships

```
User (1) ──────< (*) Library
               |  (normal: communal, scanned_list: owned)

User (1) ──────< (*) LibraryItem
               |  (added_by, updated_by tracking)

Library (1) ──< (*) LibraryItem
               |  (items in collection)

Product (1) ──< (*) LibraryItem
               |  (references to products)

User (*) ──────< (*) SharedLink
               |  (sharing tokens)
```

---

## Mental Model: Three Levels

### Level 1: Product (What exists)
"The authoritative record of a published work"
- Shared across all users
- Comes from TBDB
- One record per barcode

### Level 2: Library (Where it lives)
"A collection of items"
- Communal or personal (scanned_list)
- Flexible organization
- All users can see all libraries

### Level 3: LibraryItem (Specific instance)
"A product's presence in a library, with ownership context"
- Physical: I own this specific copy
- Virtual: I want this or am tracking it
- Tracks who added it, when, and in what state

---

## Examples

### Example 1: Personal Library
```
Library: "Study"
├── LibraryItem: Harry Potter 1 (physical, owned, mint condition)
├── LibraryItem: Board Game - Catan (physical, owned, played often)
└── LibraryItem: Whiskey - Lagavulin 16 (physical, owned, sealed)
```

### Example 2: Wishlist
```
Library: "Wishlist"
├── LibraryItem: Lego Set 12345 (virtual, notes: "Birthday gift idea")
├── LibraryItem: Harry Potter First Edition (virtual, notes: "Need dust jacket version")
└── LibraryItem: Whiskey - Macallan 30 (virtual, notes: "Someday...")
```

### Example 3: Mixed Collection
```
Library: "Harry Potter Collection"
├── LibraryItem: HP Book 1 (physical, first edition, signed)
├── LibraryItem: HP Book 2 (physical, reading copy)
├── LibraryItem: HP Book 3 (virtual, notes: "Still hunting for first edition")
└── LibraryItem: HP Book 4 (virtual, notes: "Want the Bloomsbury edition")
```

### Example 4: Scanned List (Scan Inbox)
```
Library: "Pete's Scans" (role: scanned_list, user: Pete)
├── LibraryItem: Book I just scanned (physical, not yet organized)
├── LibraryItem: Board Game I just scanned (physical, not yet organized)
└── LibraryItem: Lego Set I just scanned (virtual, want to buy)
```

### Example 5: Little Free Library
```
Library: "Little Free Library - 5th Ave"
├── LibraryItem: Children's Book 1 (physical, available for anyone)
├── LibraryItem: Children's Book 2 (physical, available for anyone)
└── LibraryItem: Mystery Novel (physical, available for anyone)
```

---

## Key Design Principles

1. **Simplicity** - Few concepts, flexible composition
2. **Communal** - All users collaborate on shared instance
3. **Physical vs Virtual** - Clear distinction between owning and wanting
4. **No Duplication** - One Product record per barcode, multiple LibraryItems
5. **Attribution** - Track who added/edited what (full transparency)
6. **Flexible Organization** - Users decide how to structure libraries
7. **Scan Inbox** - Temporary staging area for rapid scanning
