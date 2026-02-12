# TAPAS Admin Dashboard Guide

This guide shows you how to navigate and use the TAPAS admin dashboard powered by the [Administrate gem](https://administrate-demo.herokuapp.com/).

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

The sidebar navigation provides quick access to four main sections:

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
- Edit existing projects (title, description, institution, public/private status)
- Associate projects with collections, core files, and members
- Delete projects

**Filters available:**
- **Public** - Show only public projects (`is_public = true`)
- **Private** - Show only private projects (`is_public = false`)
- **Recent** - Show projects created in the last 30 days

**Note:** Project visibility filters are stored in your session and persist across page loads until cleared.

### Collections (`/admin/collections`)

**What you can do:**
- View all collections with title, parent project, depositor, and public status
- Create new collections within projects
- Edit collection details (title, description, public status)
- Associate collections with core files
- Delete collections

**Filters available:**
- **Public** - Show only public collections
- **Private** - Show only private collections

**Key relationships:**
- Each collection belongs to one project
- Collections can contain multiple core files

### Core Files (`/admin/core_files`)

**What you can do:**
- View all TEI/XML core files with title, depositor, ography type, and public status
- Upload and manage new core files
- Edit core file metadata (title, description, ography type)
- Associate core files with collections
- Delete core files

**Filters available:**
- **Public** - Show only public core files
- **Private** - Show only private core files
- **Ography** - Show core files with an ography type set (bibliography, prosopography, etc.)

**Key metadata:**
- TEI authors and contributors (extracted from TEI markup)
- Ography type classification

### Users (`/admin/users`)

**What you can do:**
- View all users with email, name, institution, admin status, and sign-in count
- Create new user accounts
- Edit user profiles (email, name, bio, institution)
- Grant or revoke admin access (set/clear `admin_at` timestamp)
- Associate users with profile images
- Delete user accounts

**Filters available:**
- **Admin** - Show only users with admin privileges (`admin_at` is set)
- **Active** - Show only users who have signed in at least once

**Key fields:**
- `admin_at` - Timestamp indicating admin status (set = admin, null = regular user)
- `sign_in_count` - Number of times user has logged in

## Additional Resources

These resources are accessible via direct URLs but not shown in the main navigation:

### Image Files (`/admin/image_files`)
- Manage uploaded images for users, projects, and other entities
- View image URL, format, and associated resource (polymorphic)

### Project Members (`/admin/project_members`)
- Manage project membership and roles
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

### Adding Core Files to a Collection
1. Go to `/admin/collections`
2. Click "Edit" on the desired collection
3. In the "Core Files" field, select the files to add
4. Click "Update Collection"

Alternatively:
1. Go to `/admin/collection_core_files`
2. Click "New Collection Core File"
3. Select the collection and core file
4. Click "Create Collection Core File"

### Finding All Public Projects
1. Go to `/admin/projects`
2. Click the "Public" filter in the collection filters section
3. Only projects with `is_public = true` will be displayed

### Viewing Active Admins
1. Go to `/admin/users`
2. Click the "Admin" filter to see all users with admin privileges
3. Or combine filters: "Admin" + "Active" to see admins who have logged in

## Navigation Tips

1. **Back to Main App** - Click "← Back to App" in the sidebar to return to the public TAPAS site
2. **Breadcrumbs** - Use the breadcrumb trail at the top to navigate back to index pages
3. **Session Filters** - Project filters persist in your session until you clear them or log out
4. **Pagination** - Large lists are paginated; use the page controls at the bottom
5. **Search** - Most index pages have a search bar to quickly find records

## Security Notes

- All admin routes require authentication via Devise
- Only users with `admin_at` set can access the admin dashboard
- Non-admin users are redirected with "Access denied" message
- Admin status is checked on every admin page load

## Technical Details

**Built with:** Administrate gem\
**Authentication:** Devise\
**Authorization:** Custom `admin?` method on User model\
**Base Controller:** `Admin::ApplicationController`\
**Routes Namespace:** `/admin/*`

For more technical details, see the implementation files:
- Routes: `config/routes.rb`
- Controllers: `app/controllers/admin/`
- Dashboards: `app/dashboards/`
- Navigation: `app/views/admin/application/_navigation.html.erb`
