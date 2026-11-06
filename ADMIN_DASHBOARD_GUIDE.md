# TAPAS Admin Dashboard Guide

This guide shows you how to navigate and use the TAPAS admin dashboard. The admin pages are plain Rails controllers and views in the `admin` namespace (they replaced the Administrate gem in October 2026), and they load JavaScript the same way as the rest of the app.

## Accessing the Admin Dashboard

### Prerequisites
1. You must have a user account in the TAPAS application
2. Your user account must have admin privileges

### Accessing the Dashboard
1. Start the Rails server: `rails server`
2. Navigate to: `http://localhost:3000/admin`
3. If not logged in, you'll be redirected to the login page
4. Log in with your admin-privileged user account

## Dashboard Overview

The admin dashboard provides a centralized interface to manage all TAPAS data. When you access `/admin`, you'll land on the Projects index page by default.

### Main Navigation

The sidebar navigation links to two review queues and four main sections:

- **New Account Review** - Approve or reject newly registered accounts, one at a time or in bulk
- **Invitation Links** - See and revoke active project invitation links
- **Projects** - Manage research projects
- **Collections** - Manage document collections
- **Core Files** - Manage TEI/XML core files
- **Users** - Manage user accounts

Additional resources (Image Files, Project Members, Collection Core Files, View Packages) are accessible via direct URLs but not shown in the main navigation.

## Managing Resources

### Projects (`/admin/projects`)

**What you can do:**
- View all projects with title, depositor, institution, public status, and creation date
- Create new projects
- Edit existing projects (depositor, title, description, institution, public/private status, image)
- See a project's collections, core files, members and users on its page, each linked to its own admin page
- Delete projects

Collections, members and users are edited from their own pages, not from the project form. (The old form let you edit them as lists, and deselecting one there deleted it.)

**Filters available:**
- **Public / Private buttons** - Show only public or private projects. Your choice is stored in your session until you click "All Projects".
- **Recent button** - Show projects created in the last 30 days (same as typing `recent:` in the search box)
- `public:` and `private:` can also be typed into the search box; they have no buttons of their own because the Public / Private buttons cover them

### Collections (`/admin/collections`)

**What you can do:**
- View all collections with title, parent project, depositor, and public status
- Create new collections within projects
- Edit collection details (depositor, project, title, description, public status, image)
- See a collection's core files on its page
- Delete collections

To add a core file to a collection, edit the core file and choose its collections.

**Filters available** (buttons above the list, or typed into the search box):
- `public:` - Show only public collections
- `private:` - Show only private collections

**Key relationships:**
- Each collection belongs to one project
- Collections can contain multiple core files

### Core Files (`/admin/core_files`)

**What you can do:**
- View all TEI/XML core files with title, depositor, ography type, and public status
- Create core file records
- Edit core file metadata (title, description, depositor, ography type, public status)
- Choose which collections a core file belongs to (all must be in the same project)
- Retry TAPAS-XQ processing for a file whose processing failed, and see the error
- Delete core files

**Filters available** (buttons above the list, or typed into the search box):
- `public:` - Show only public core files
- `private:` - Show only private core files
- `ography:` - Show core files with an ography type set (bibliography, prosopography, etc.)
- `processing_failed:` / `processing_pending:` - Show files by TAPAS-XQ processing status

**Key metadata:**
- TEI authors and contributors (extracted from TEI markup)
- Ography type classification

### Users (`/admin/users`)

**What you can do:**
- View all users with email, name, institution, admin status, and sign-in count
- Edit user profiles (account status, email, name, bio, institution)
- Grant or revoke admin access (set/clear `admin_at` timestamp)
- Associate users with profile images
- Delete user accounts

There is no "New user" button: the admin form can't set a password, so accounts are created through sign-up.

Search covers email, name and institution. Password hashes and reset tokens are never shown or searched.

**Filters available** (buttons above the list, or typed into the search box):
- `admin:` - Show only users with admin privileges (`admin_at` is set)
- `active:` - Show only users who have signed in at least once

**Key fields:**
- `admin_at` - Timestamp indicating admin status (set = admin, null = regular user)
- `sign_in_count` - Number of times user has logged in

## Additional Resources

These resources are accessible via direct URLs but not shown in the main navigation:

### Image Files (`/admin/image_files`)
- Manage uploaded images for users, projects, and other entities
- View image URL, format, and associated resource (polymorphic)
- Edit image details. Images are added from the record they belong to (user, project, collection), so there is no "New" button here

### Project Members (`/admin/project_members`)
- Manage project membership and roles (contributor or owner)
- Set project depositor status
- Associate users with projects

### Collection Core Files (`/admin/collection_core_files`)
- Manage the many-to-many relationship between collections and core files
- Junction table for associating core files with collections

### View Packages (`/admin/view_packages`)
- Manage view rendering configurations
- Configure CSS, JavaScript, and display parameters

## Common Tasks

### Making a User an Admin
1. Go to `/admin/users`
2. Find the user in the list
3. Click "Edit" next to their record
4. Set the `admin_at` field to the current date/time
5. Click "Update User"

### Creating a New Project
1. Go to `/admin/projects`
2. Click "New Project"
3. Fill in required fields:
   - Title
   - Depositor (select from users)
   - Description
   - Institution
   - Public/Private status
4. Click "Create Project"

### Adding a Core File to a Collection
1. Go to `/admin/core_files`
2. Open the core file and click "Edit"
3. In the "Collections" field, select the collections (hold Cmd or Ctrl to select more than one)
4. Click "Update Core file"

Alternatively:
1. Go to `/admin/collection_core_files/new`
2. Select the collection and core file
3. Click "Create Collection core file"

### Reviewing New Accounts
1. Click "New Account Review" in the sidebar
2. Approve or Reject a single account with the buttons on its row, or
3. Tick several accounts (or the box in the header to select all) and click "Approve Selected" or "Reject Selected"
4. Confirm the prompt. Approved users get an email; rejected registrations are deleted silently

### Finding All Public Projects
1. Go to `/admin/projects`
2. Click the "Public" button above the list
3. Only projects with `is_public = true` will be displayed

### Viewing Active Admins
1. Go to `/admin/users`
2. Click the "Admin" filter button (or type `admin:` in the search box and press Enter)
3. Click "Active" too to see only admins who have logged in (`admin: active:`)

## Navigation Tips

1. **Back to Main App** - Click "← Back to App" in the sidebar to return to the public TAPAS site
2. **Sorting** - Column headings with an arrow (↕) can be sorted. Click one to sort; click again to reverse. The sorted column shows ▲ (ascending) or ▼ (descending)
3. **Session Filters** - Project filters persist in your session until you clear them or log out
4. **Pagination** - Lists show 20 records per page; use the page controls at the bottom
5. **Search** - Most index pages have a search bar; press Enter to search, and click the x to clear it
6. **Filter buttons** - Click a filter button to turn it on (it fills in) and click again to turn it off. Buttons and typed filters are the same thing: the button just adds or removes its keyword in the search box, and you can combine filters with search text

## Security Notes

- All admin routes require authentication via Devise
- Only users with `admin_at` set can access the admin dashboard
- Non-admin users are redirected with "Access denied" message
- Admin status is checked on every admin page load

## Technical Details

**Built with:** Plain Rails controllers and ERB views, simple_form, Kaminari pagination\
**Authentication:** Devise\
**Authorization:** Custom `admin?` method on User model\
**Base Controller:** `Admin::BaseController`\
**Routes Namespace:** `/admin/*`

For more technical details, see the implementation files:
- Routes: `config/routes.rb`
- Controllers: `app/controllers/admin/` (search, filters, sorting and pagination: `app/controllers/concerns/admin/resource_index.rb`)
- Shared views: `app/views/admin/base/`
- Navigation: `app/views/admin/application/_navigation.html.erb`
- Styles: `app/assets/stylesheets/admin.scss` (styles ported from Administrate live in `app/assets/stylesheets/admin/administrate/`)
