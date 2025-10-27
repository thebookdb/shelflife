# ShelfLife

A personal library management application for tracking books, DVDs, board games, and other media through barcode scanning.

## Docker Deployment

ShelfLife is designed to run as a single Docker container with SQLite and Rails' Solid adapters for caching, queuing, and real-time features.

Barcode scanning is the ideal method of getting data into Shelflife, and using a Camera on a web app requires HTTPS.   Alternatively, you can edit your library and manually import products, by entering their barcode / ISBNs. 

### Building the Docker Image

#### Simple Build
```bash
docker build -t shelflife .
```

#### Multi-Architecture Build (Recommended)
Use the included build script for AMD64 + ARM64 images:

```bash
# Build for local testing
bin/build

# Build and tag with version
bin/build -v v1.0.0

# Build and push to GitHub Container Registry
bin/build -v v1.0.0 -p

# Build and push to Docker Hub instead
bin/build -v v1.0.0 -p -r dockerhub
```

**Tags Created:**
- `latest` - Always points to the most recent build
- `<git-hash>` - Immutable reference to exact commit (e.g., `a1b2c3d`)
- `<version>` - Semantic version if specified (e.g., `v1.0.0`)

### Running with Docker

Run the container with a volume for persistent data:

```bash
docker run -d \
  -p 3000:80 \
  -v shelflife_data:/rails/storage \
  -e RAILS_MASTER_KEY=<your_master_key> \
  --name shelflife \
  shelflife
```

The application will be available at http://localhost:3000

### Pre-built Images

#### GitHub Container Registry (Recommended)
```bash
# Pull the latest image
docker pull ghcr.io/dkam/shelflife:latest

# Run the pre-built image
docker run -d \
  -p 3000:80 \
  -v shelflife_data:/rails/storage \
  -e RAILS_MASTER_KEY=<your_master_key> \
  --name shelflife \
  ghcr.io/dkam/shelflife:latest
```

#### Docker Compose
Create a `.env` file with `SECRET_KEY_BASE=...` value in it.  

To generate the SECRET_KEY_BASE value, use `openssl rand -hex 64`

Then create the storage and log directories.

```
services:
  web:
    image: ghcr.io/thebookdb/shelf-life:latest  # Using GitHub Container Registry
    ports:
      - "3000:80"
    environment:
      - RAILS_ENV=production
      - SECRET_KEY_BASE=${SECRET_KEY_BASE}
      - RAILS_LOG_TO_STDOUT=true
    volumes:
      - ./storage:/rails/storage
      - ./log:/rails/log
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80/up"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
```
### Environment Variables

- `RAILS_MASTER_KEY`: Required for decrypting credentials
- `RAILS_ENV`: Set to `production` (default in Docker)

#### Generating the Master Key

The master key is required to decrypt Rails credentials. You have a few options:

**Option 1: Use the existing key from this repository**
```bash
# Copy the key from config/master.key (if you have access to this repo)
cat config/master.key
```

**Option 2: Generate a new master key for your installation**
```bash
# This will create new config/master.key and config/credentials.yml.enc files
rails credentials:edit

# Or generate just the key
openssl rand -hex 32
```

**Option 3: Use a simple key for testing (not recommended for production)**
```bash
# Generate a simple random key
ruby -e "puts SecureRandom.hex(16)"
```

When running Docker, use the key like this:
```bash
docker run -d \
  -p 3000:80 \
  -v shelflife_data:/rails/storage \
  -e RAILS_MASTER_KEY=6a6f0a07b11c2b1b954ea2b126ad4b36 \
  --name shelflife \
  shelflife
```

### Data Persistence

Mount a volume to `/rails/storage` to persist:
- SQLite databases
- User uploads (cover images)
- Cache and queue data

## Development Setup

For local development without Docker:

### Requirements

* Ruby 3.4.5
* Node.js 24.4.1
* SQLite3

### Setup

```bash
# Install dependencies
bundle install
npm install

# Setup database
bin/rails db:create db:migrate db:seed

# Start development server
overmind start -f Procfile.dev
# or
foreman start -f Procfile.dev
```

### Development Commands

- `bin/rails server` - Start Rails server
- `bin/rails console` - Rails console
- `bin/rails test` - Run tests
- `npm run build` - Build JavaScript
- `npm run build:css` - Build CSS
- `bundle exec rubocop` - Ruby linting
- `bundle exec brakeman` - Security analysis
