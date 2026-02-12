Development Environment Configuration Guide
===========
This document outlines steps for configuring your environment to run TAPAS locally by installing the prerequisites.

## Installing TAPAS and dependencies

First, get a local copy of the TAPAS repository:

```shell
git clone https://github.com/NEU-DSG/TAPAS.git
cd TAPAS
```

We recommend the [Homebrew](https://brew.sh/) package manager to install software dependencies. To install packages with Homebrew, use the command pattern `brew install PKG_NAME`.

### Install Ruby

TAPAS requires Ruby version >= 4.0.0.

1. [Install Ruby Version Manager (RVM)](http://rvm.io/rvm/install), using the RVM instructions.
2. Install [Xcode](https://developer.apple.com/xcode/) from the Mac App Store.
    1. Install the Command Line Tools package with `xcode-select --install`.
3. Install the `automake` package with your package manager.
4. Install the `openssl@3` package with your package manager.
5. Install Ruby:
    1. Try RVM's default install, `rvm install ruby-4.0.0` (or the shorthand `rvm install 4.0.0`).
    2. If the installation failed because the ruby source couldn't be compiled, provide the OpenSSL path, e.g.: `rvm install ruby-4.0.0 -C --with-openssl-dir='/opt/homebrew/bin/openssl'`.

### Install Apache Solr

Apache Solr v9.10.1 is required for TAPAS. Solr 9 requires Java 17 LTS or 21 LTS — Java 24 and other non-LTS releases are not supported.

**Check your Java version:**
```bash
java -version
# Should show openjdk version "21.x.x" or "17.x.x"
```

If needed, install Java 21 via Homebrew:
```bash
brew install openjdk@21
export JAVA_HOME=$(brew --prefix openjdk@21)
```

**Install Solr:**
1. Download [Apache Solr 9.10.1](https://solr.apache.org/downloads.html).
2. Extract the tarball: `tar -xzf solr-9.10.1.tgz`
3. Move to your preferred location, e.g.: `mv solr-9.10.1 ~/solr-9.10.1`

**Set the SOLR_HOME environment variable** to your Solr installation path. Add this to your shell profile (`.bashrc`, `.zshrc`, etc.) so it persists across sessions:
```bash
export SOLR_HOME=/path/to/solr-9.10.1
```

**Start Solr:**
```bash
$SOLR_HOME/bin/solr start
```

**Set up the TAPAS configset:**

TAPAS uses a named Solr configset so that configuration stays in the repository and any new core automatically picks it up.

```bash
# Create the configset directory
mkdir $SOLR_HOME/server/solr/configsets/tapas

# Symlink the repo's config files into it (replace /path/to/TAPAS with your local repo path)
ln -s /path/to/TAPAS/solrconfig/tapas/conf \
      $SOLR_HOME/server/solr/configsets/tapas/conf
```

**Create the TAPAS core:**
```bash
$SOLR_HOME/bin/solr create -c tapas-core -n tapas
```

#### Verify the core's existence

1. Open the [Solr Admin Dashboard](http://localhost:8983/solr/#/) in your browser
2. Click the **Core Selector** dropdown on the left
3. Verify `tapas-core` is listed

To stop Solr: `$SOLR_HOME/bin/solr stop`


### Install MySQL

MySQL 8.0 or higher is recommended.

**Install MySQL:**
```bash
# macOS with Homebrew
brew install mysql

# Start MySQL service
brew services start mysql

# Secure the installation (set root password, etc.)
mysql_secure_installation
```

**Set up a MySQL user for TAPAS:**
```bash
# Log into MySQL as root
sudo mysql -u root -p

# In the MySQL prompt, create the TAPAS user
CREATE USER 'tapas_user'@'localhost' IDENTIFIED BY 'changeThisPassword!';
GRANT ALL ON *.* TO 'tapas_user'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
\q
```

### Install and configure Rails

TAPAS uses Ruby on Rails v8.1.2.

1. **Navigate to your TAPAS directory:**
   ```bash
   cd TAPAS
   ```

2. **Install Rails:**
   ```bash
   gem install rails -v 8.1.2
   ```

3. **Install ImageMagick** (required for image processing):
   ```bash
   brew install imagemagick
   ```

4. **Install the mysql2 gem:**
   ```bash
   # On macOS with Homebrew
   gem install mysql2 -- --with-mysql-dir=$(brew --prefix mysql) --with-openssl-dir=$(brew --prefix openssl@3)
   ```

   Note: The `mysql2` gem must install successfully before proceeding. If you encounter errors, see the [`mysql2` installation guide](https://github.com/brianmario/mysql2#installing).

5. **Configure environment variables:**
   ```bash
   # Copy the example file
   cp .env.example .env

   # Edit .env with your credentials
   # Update MYSQL_USER and MYSQL_PASSWORD at minimum
   # Also set DUMMY_ADMIN_EMAIL, DUMMY_ADMIN_PASSWORD, etc. for test data
   ```

6. **Run the setup script:**
   ```bash
   bin/setup --skip-server
   ```

   This will:
   - Install all gem dependencies with `bundle install`
   - Create the databases (`tapas_development` and `tapas_test`)
   - Run database migrations
   - Clear logs and temp files

   The `--skip-server` flag prevents the script from automatically starting the server.

### Install and configure TAPAS-xq

TAPAS-xq is the BaseX XML database that TAPAS uses to store and transform TEI files. It is required for full TEI file processing — uploading a TEI file, receiving MODS metadata back, and generating HTML fragments for the TAPAS reader.

For full setup instructions, refer to the [TAPAS-xq README](https://github.com/NEU-DSG/tapas-xq).

Once TAPAS-xq is running, configure the following environment variables in your `.env` file:

| Variable | Description | Default |
|---|---|---|
| `TAPAS_XQ_BASE_URL` | Base URL of the TAPAS-xq API | `http://localhost:8080/tapas-xq` |
| `TAPAS_XQ_USERNAME` | TAPAS-xq API username | — |
| `TAPAS_XQ_PASSWORD` | TAPAS-xq API password | — |
| `TAPAS_XQ_TIMEOUT` | Request timeout in seconds | `30` |
| `TAPAS_XQ_ENABLED` | Set to `false` to disable TAPAS-xq integration | `true` |

**Running without TAPAS-xq:**

If you are working on parts of TAPAS that do not involve TEI file processing, you can disable the integration entirely by setting `TAPAS_XQ_ENABLED=false` in your `.env` file. With this setting, the job that processes TEI files will log that TAPAS-xq is disabled and leave the file's status as `pending` rather than attempting an API call. Files can be reprocessed once TAPAS-xq is enabled again.

### Create test data

To create fake users, projects, collections, and core files for testing:

```bash
rails dummy_data_generator:run_all
```

This task will:
- Check your background job configuration (AsyncAdapter is configured for development)
- Restart Solr to ensure connectivity
- Create admin and debug users (using credentials from `.env`)
- Create 275+ test users
- Create 25 projects with images
- Create project members
- Create collections with images
- Create core files with TEI attachments

The task encompasses several subtasks that can be run independently:
```bash
# List all available dummy data tasks
rails --tasks dummy_data_generator

# Examples of individual tasks
rails dummy_data_generator:user_records        # Create users only
rails dummy_data_generator:projects            # Create projects only
rails dummy_data_generator:collections         # Create collections only
rails dummy_data_generator:core_files          # Create core files only
```

**Background Job Processing:**
- TAPAS is configured with `AsyncAdapter` for development, which processes jobs in background threads automatically
- No external worker processes are required in development
- Files will be processed automatically after upload
- Production uses Solid Queue for persistent, database-backed job processing

### Verify test data

**Check MySQL databases:**
```bash
# Enter MySQL CLI
mysql -u tapas_user -p

# In MySQL prompt
SHOW DATABASES;                    # See all databases
USE tapas_development;             # Switch to development database
SHOW TABLES;                       # List all tables
SELECT * FROM users;               # View user records
SELECT * FROM projects;            # View project records
\q                                 # Quit MySQL CLI
```

**Check Solr index:**
1. Open [Solr Admin Dashboard](http://localhost:8983) in your browser
2. Select `tapas-core` from the Core Selector dropdown
3. Click the "Overview" tab to view indexed record counts

Solr indexes projects, collections, and core files, but not user records.


## Run TAPAS

### Start the development server

TAPAS uses `bin/dev` to run all necessary services simultaneously:

```bash
bin/dev
```

This starts:
- **Rails server** on `http://localhost:3000`
- **Dart Sass watcher** for CSS compilation

The development server will automatically:
- Process background jobs using AsyncAdapter (configured in `config/environments/development.rb`)
- Handle file uploads and attachments
- Recompile assets when files change

**Visit the application:** `http://localhost:3000`

### Alternative: Run Rails server only

To run the Rails server without the asset watcher:

```bash
bin/rails server
# or
rails s
```

Note: With this approach, you'll need to precompile assets or run the Sass watcher separately if you modify stylesheets.

### Stopping the server

Press `Ctrl+C` to stop the server.

### Login credentials

After running the dummy data generator, you can log in with:

**Admin user:**
- Email: Value of `DUMMY_ADMIN_EMAIL` from your `.env` file
- Password: Value of `DUMMY_ADMIN_PASSWORD` from your `.env` file

**Debug user:**
- Email: Value of `DUMMY_DEBUG_EMAIL` from your `.env` file
- Password: Value of `DUMMY_DEBUG_PASSWORD` from your `.env` file

## Testing

### Test framework

TAPAS uses:
- [rspec-rails](https://github.com/rspec/rspec-rails) - Testing framework
- [factory_bot](https://github.com/thoughtbot/factory_bot_rails) - Test data factories
- [faker](https://github.com/faker-ruby/faker) - Fake data generation
- [capybara](https://github.com/teamcapybara/capybara) - Integration testing
- [selenium-webdriver](https://github.com/SeleniumHQ/selenium) - Browser automation

### Running tests

```bash
# Run all tests
bundle exec rspec

# Run a specific test file
bundle exec rspec spec/models/user_spec.rb

# Run a specific test
bundle exec rspec spec/models/user_spec.rb:10
```

## Troubleshooting

### General issues
- Stop the server: `Ctrl+C`
- Clear logs: `rails log:clear`
- Clear temp files: `rails tmp:clear`
- Reset database: `rails db:reset` (WARNING: destroys all data)

### Database connection errors
- Verify MySQL is running: `mysql.server status` or `brew services list`
- Check `.env` file has correct `MYSQL_USER` and `MYSQL_PASSWORD`
- Verify socket path in `config/database.yml` matches your MySQL installation

### Asset compilation issues
- Try clearing assets: `rails assets:clobber`
- Ensure Node.js is installed: `node --version`
- Restart the development server

### ImageMagick issues
- Verify installation: `convert --version`
- Reinstall if needed: `brew reinstall imagemagick`

### Solr connection issues
- Verify Solr is running: `$SOLR_HOME/bin/solr status`
- Restart Solr: `$SOLR_HOME/bin/solr restart`
- Check the core exists: Visit http://localhost:8983/solr/#/ and confirm `tapas-core` appears in the Core Selector

### Background job issues
TAPAS uses AsyncAdapter in development, which runs automatically. If jobs aren't processing:
- Check Rails logs: `tail -f log/development.log`
- Verify the configuration in `config/environments/development.rb` shows `config.active_job.queue_adapter = :async`

## Additional Resources

- [Rails 8 Documentation](https://guides.rubyonrails.org/)
- [Blacklight Documentation](https://github.com/projectblacklight/blacklight)
- [Solr Documentation](https://solr.apache.org/guide/)
- [RSpec Documentation](https://rspec.info/)
- [Devise Documentation](https://github.com/heartcombo/devise) (Authentication)
- [CanCanCan Documentation](https://github.com/CanCanCommunity/cancancan) (Authorization)
