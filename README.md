# TAPAS

The TEI Archiving, Publishing, and Access Service (TAPAS) web application.

* Archived pre-2025 [version](https://github.com/NEU-DSG/tapas_rails)

## Prerequisites

Before setting up the application, see the [Dev Environment Configuration guide](DEVELOPMENT_ENVIRONMENT_CONFIGURATION_GUIDE.md) and ensure you have the following installed:

- **Ruby** 4.0.0 (see `.ruby-version`)
- **MySQL** 8.0 or higher
- **Bundler** gem
- **ImageMagick** (for image processing)
- **Solr** 8.11.2 (for search functionality)
- **Node.js** and **npm** (for asset compilation)

## Local Development Setup

### 1. Clone the Repository
```bash
git clone https://github.com/NEU-DSG/TAPAS.git
cd TAPAS
```

### 2. Install Ruby Dependencies
```bash
bundle install
```

### 3. Configure Environment Variables

Copy the example environment file and update with your configuration:

```bash
cp .env.example .env
```

Then edit `.env` with your MySQL credentials and other configuration as needed.

### 4. Setup MySQL Database

Ensure MySQL is running, then create the databases:

```bash
# Start MySQL service (macOS)
brew services start mysql

# Start MySQL service (Linux)
sudo systemctl start mysql
```

### 5. Run Setup Script

The setup script will install dependencies, create and migrate the database:

```bash
bin/setup
```

This script will:
- Install all gem dependencies
- Create and migrate the database
- Clear logs and temp files
- Start the development server

### 6. Start the Development Server

To run the application with all services (web server + asset compilation):

```bash
bin/dev
```

This will start:
- Rails server on `http://localhost:3000`
- Dart Sass watcher for CSS compilation

Alternatively, you can run the Rails server alone:
```bash
bin/rails server
```

### 7. Setup Solr (Search)

Start Solr for search functionality:

```bash
# Start Solr
solr start
```

## Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/path/to/test_spec.rb
```

## TAPAS-XQ Integration

TAPAS-XQ is the XML database component (BaseX) that stores TEI files and generates MODS metadata for the TAPAS application.

### Configuration

Set these environment variables in your `.env` file:

```bash
# TAPAS-XQ Configuration (BaseX XML Database)
TAPAS_XQ_BASE_URL='http://localhost:8080/tapas-xq'
TAPAS_XQ_USERNAME='admin'
TAPAS_XQ_PASSWORD='admin'
TAPAS_XQ_TIMEOUT=30
TAPAS_XQ_ENABLED=true  # Set to false to disable in development
```

### Setting Up TAPAS-XQ Locally

For local development with TAPAS-XQ, refer to the Docker setup in `.admin-documentation/tapas-xq-api/docker/`. You can start TAPAS-XQ using Docker:

```bash
# Navigate to the docker directory
cd .admin-documentation/tapas-xq-api/docker

# Start TAPAS-XQ with Docker Compose
docker-compose up
```

### Local Development Without TAPAS-XQ

You can develop without a local TAPAS-XQ instance by setting `TAPAS_XQ_ENABLED=false` in your `.env` file. Background jobs will complete immediately without making API calls, and files will be marked as "completed" without actual processing.

```bash
TAPAS_XQ_ENABLED=false
```

### How It Works

1. **User uploads TEI file** via the admin interface at `/admin/core_files/new`
2. **Background job enqueued** automatically via `ProcessTeiFileJob`
3. **Job sends TEI to TAPAS-XQ**, which:
   - Stores TEI in BaseX XML database
   - Generates MODS metadata from TEI header
   - Generates TFE (TAPAS-friendly environment) metadata
   - Returns MODS XML
4. **MODS stored in database** and file indexed to Solr for search

### Monitoring Processing Status

View and manage TEI processing in the admin interface:

- **List view**: Shows `processing_status` column (pending, processing, completed, failed)
- **Filters**: Use `processing_failed:` or `processing_pending:` in the search box
- **Show page**: Displays processing status, errors, and MODS XML
- **Retry button**: Appears on failed files to re-submit to TAPAS-XQ

### Rake Tasks

Several rake tasks are available for TAPAS-XQ operations:

```bash
# Check TAPAS-XQ connection
rails tapas_xq:check_connection

# Show processing status summary
rails tapas_xq:status

# Retry all failed processing
rails tapas_xq:retry_failed

# Sync MODS from TAPAS-XQ for a specific CoreFile
rails tapas_xq:sync_mods[123]

# Reprocess all CoreFiles (use with caution)
rails tapas_xq:reprocess_all
```

### Troubleshooting

**Connection errors:**
- Verify TAPAS-XQ is running: `rails tapas_xq:check_connection`
- Check `TAPAS_XQ_BASE_URL` is correct
- Ensure credentials match your TAPAS-XQ installation

**Processing failures:**
- View error details on the CoreFile show page in admin
- Check SolidQueue logs for job failures
- Use retry button or `rails tapas_xq:retry_failed`

**Background job not processing:**
- Ensure SolidQueue workers are running (happens automatically in development)
- Check `config/queue.yml` for worker configuration
- In production, ensure sufficient `JOB_CONCURRENCY` (environment variable)

### Testing

Tests use WebMock to stub TAPAS-XQ HTTP calls, so no live TAPAS-XQ instance is needed for testing:

```bash
# Run TAPAS-XQ related tests
bundle exec rspec spec/services/tapas_xq/
bundle exec rspec spec/jobs/process_tei_file_job_spec.rb
bundle exec rspec spec/models/core_file_spec.rb
```

## Code Quality Tools

```bash
# Run RuboCop linter
bin/rubocop

# Check for security vulnerabilities
bin/bundler-audit
bin/brakeman
```

## Troubleshooting

### Database Connection Issues
- Verify MySQL is running: `mysql.server status` (macOS) or `sudo systemctl status mysql` (Linux)
- Check your `.env` file has correct `MYSQL_USER` and `MYSQL_PASSWORD`
- Verify the socket path in `config/database.yml` matches your MySQL installation

### Asset Compilation Issues
- Make sure Node.js and npm are installed
- Try clearing precompiled assets: `bin/rails assets:clobber`

### ImageMagick Issues
- Verify ImageMagick is installed: `convert --version`
- On macOS, you may need to reinstall: `brew reinstall imagemagick`

## Additional Resources

### Documentation
- [Admin Dashboard Guide](ADMIN_DASHBOARD_GUIDE.md) - Guide to using the Administrate-powered admin interface
- [Development Environment Configuration Guide](DEVELOPMENT_ENVIRONMENT_CONFIGURATION_GUIDE.md) - Detailed setup instructions

### External Resources
- [Rails 8 Documentation](https://guides.rubyonrails.org/)
- [Blacklight Documentation](https://github.com/projectblacklight/blacklight)
- [Solr Documentation](https://solr.apache.org/guide/)

