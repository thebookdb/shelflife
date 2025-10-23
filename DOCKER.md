# Accessing Docker Images

ShelfLife Docker images are automatically built and published to GitHub Container Registry (GHCR) via GitHub Actions.

## Quick Start

```bash
# Pull and run the latest image
docker pull ghcr.io/thebookdb/shelflife:latest
docker run -d \
  -p 3000:80 \
  -v shelflife_data:/rails/storage \
  -e RAILS_MASTER_KEY=<your_master_key> \
  --name shelflife \
  ghcr.io/thebookdb/shelflife:latest
```

## Image Registry

**GitHub Container Registry (GHCR)**
- Registry: `ghcr.io`
- Organization: `thebookdb`
- Package: `shelflife`
- Full path: `ghcr.io/thebookdb/shelflife`

## Available Tags

Images are automatically tagged based on the trigger:

### Main Branch Builds
- `latest` - Always points to the latest main branch build
- `main` - Same as latest, from main branch
- `main-<sha>` - Specific commit SHA from main (e.g., `main-abc1234`)

### Tagged Releases
- `v1.0.0` - Full semantic version
- `v1.0` - Major.minor version
- `v1` - Major version only

### Pull Request Builds
- `pr-<number>` - Built for testing PRs (e.g., `pr-123`)

## Viewing Available Images

### Web Interface
Visit the GitHub Container Registry package page:
https://github.com/thebookdb/shelflife/pkgs/container/shelflife

### Using GitHub CLI
```bash
# List all versions
gh api /orgs/thebookdb/packages/container/shelflife/versions

# View package metadata
gh api /orgs/thebookdb/packages/container/shelflife
```

### Using Docker CLI
```bash
# Search for available tags (requires authentication)
docker pull ghcr.io/thebookdb/shelflife:latest
docker image inspect ghcr.io/thebookdb/shelflife:latest
```

## Authentication

### Public Access
ShelfLife images are published as **public** packages, so no authentication is required to pull them:

```bash
docker pull ghcr.io/thebookdb/shelflife:latest
```

### Authenticated Access (Optional)
If you need to push images or access private packages, authenticate with a GitHub Personal Access Token (PAT):

```bash
# Create a PAT with 'read:packages' scope at:
# https://github.com/settings/tokens

# Login to GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
```

## Examples

### Run Latest Version
```bash
docker pull ghcr.io/thebookdb/shelflife:latest
docker run -d \
  -p 3000:80 \
  -v shelflife_data:/rails/storage \
  -e RAILS_MASTER_KEY=$(cat config/master.key) \
  --name shelflife \
  ghcr.io/thebookdb/shelflife:latest
```

### Run Specific Version
```bash
docker pull ghcr.io/thebookdb/shelflife:v1.0.0
docker run -d \
  -p 3000:80 \
  -v shelflife_data:/rails/storage \
  -e RAILS_MASTER_KEY=$(cat config/master.key) \
  --name shelflife \
  ghcr.io/thebookdb/shelflife:v1.0.0
```

### Run Specific Commit
```bash
docker pull ghcr.io/thebookdb/shelflife:main-abc1234
docker run -d \
  -p 3000:80 \
  -v shelflife_data:/rails/storage \
  -e RAILS_MASTER_KEY=$(cat config/master.key) \
  --name shelflife \
  ghcr.io/thebookdb/shelflife:main-abc1234
```

## Building Images Yourself

If you want to build and push images manually:

### Using the Build Script
```bash
# Build locally
bin/build

# Build and push to GHCR
bin/build -p

# Build specific version and push
bin/build -v v1.2.3 -p
```

### Manual Docker Build
```bash
# Build
docker build -t ghcr.io/thebookdb/shelflife:latest .

# Push (requires authentication)
docker push ghcr.io/thebookdb/shelflife:latest
```

## Automated Builds

Docker images are automatically built and pushed via GitHub Actions when:

1. **Commits to main branch** - Creates `latest`, `main`, and `main-<sha>` tags
2. **Tagged releases** - Creates semantic version tags (e.g., `v1.0.0`, `v1.0`, `v1`)
3. **Pull requests** - Builds images for testing (not pushed to registry)

See `.github/workflows/docker.yml` for the workflow configuration.

## Architecture Support

All images are built for multiple architectures:
- `linux/amd64` (x86_64)
- `linux/arm64` (ARM64/Apple Silicon)

Docker will automatically pull the correct architecture for your platform.

## Troubleshooting

### Image Not Found
If you get "image not found" errors:

1. Check that the package exists: https://github.com/thebookdb/shelflife/pkgs/container/shelflife
2. Verify the tag exists in the package versions
3. Ensure you're using the correct registry path: `ghcr.io/thebookdb/shelflife`

### Authentication Errors
If you need to push images:

1. Create a GitHub PAT with `write:packages` scope
2. Login: `echo $TOKEN | docker login ghcr.io -u USERNAME --password-stdin`
3. Push: `docker push ghcr.io/thebookdb/shelflife:tag`

### Old Images
Images with old registry paths (e.g., `ghcr.io/dkam/shelflife`) are deprecated. Use `ghcr.io/thebookdb/shelflife` instead.
