# ShelfLife

A personal library management application for tracking books, DVDs, board games, and other media through barcode scanning.

## Docker Deployment

ShelfLife is designed to run as a single Docker container with SQLite and Rails' Solid adapters for caching, queuing, and real-time features.

> **📦 For detailed information about accessing pre-built Docker images, see [DOCKER.md](DOCKER.md)**

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

Pre-built Docker images are automatically published to GitHub Container Registry (GHCR) on every push to the main branch and on tagged releases.

#### GitHub Container Registry

**Available Image Tags:**
- `latest` - Latest build from the main branch
- `v*` - Semantic version tags (e.g., `v1.0.0`, `v1.0`, `v1`)
- `main` - Latest build from main branch
- `main-<sha>` - Specific commit from main branch
- `<sha>` - Any specific commit SHA

**Pull and run the latest image:**
```bash
# Pull the latest image
docker pull ghcr.io/thebookdb/shelflife:latest

# Run the pre-built image
docker run -d \
  -p 3000:80 \
  -v shelflife_data:/rails/storage \
  -e RAILS_MASTER_KEY=<your_master_key> \
  --name shelflife \
  ghcr.io/thebookdb/shelflife:latest
```

**Pull a specific version:**
```bash
# Pull a specific semantic version
docker pull ghcr.io/thebookdb/shelflife:v1.0.0

# Pull a specific commit
docker pull ghcr.io/thebookdb/shelflife:main-abc1234
```

**Viewing Available Images:**

You can view all published images at:
https://github.com/thebookdb/shelflife/pkgs/container/shelflife

Or use the GitHub CLI:
```bash
gh api /orgs/thebookdb/packages/container/shelflife/versions
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
