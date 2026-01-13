# TAPAS

The TEI Archiving, Publishing, and Access Service (TAPAS) web application.

* Archived pre-2025 [version](https://github.com/NEU-DSG/tapas_rails)

## Prerequisites

Before setting up the application, ensure you have the following installed:

- **Ruby** 4.0.0 (see `.ruby-version`)
- **MySQL** 8.0 or higher
- **Bundler** gem
- **ImageMagick** (for image processing)
- **Solr** 8.11.2(for search functionality)
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

# Create a Solr core for TAPAS (adjust core name as needed)
solr create -c tapas_development
```

## Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/path/to/test_spec.rb
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

- [Rails 8 Documentation](https://guides.rubyonrails.org/)
- [Blacklight Documentation](https://github.com/projectblacklight/blacklight)
- [Solr Documentation](https://solr.apache.org/guide/)

