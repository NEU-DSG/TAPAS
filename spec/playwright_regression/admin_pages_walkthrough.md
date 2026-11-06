# Admin pages: Playwright walkthrough

Origin: the branch that replaces the Administrate gem with plain Rails admin
pages (`replace-administrate`), 2026-10-16. Walked through with Playwright
(headless Chromium, 1400×900) against the dev server; every **Expect** line
below was checked in that run, and each step's screenshot shows what you
should see. Screenshots live in [`admin_pages/`](admin_pages/).

Covers: admin-only access, the new layout loading the app's JavaScript, list
pages (search, sort arrows, filter buttons, pagination), view and edit pages,
the account review page (per-row and bulk approve/reject, the bug this branch
fixes), invitation link revoke, core file retry processing, and the form
choices made during review (no related-record lists on project and collection
forms, role dropdown, no "New" button for image files or users).

## Setup

1. Start Solr (`http://localhost:8983/solr/#/tapas-core` should load).
2. `bin/rails dartsass:build` (the build output is gitignored; skip this and the
   pages look unstyled). The deprecation warnings it prints all come from
   Bootstrap 5.3.8 and appear on `main` too.
3. `bin/rails db:seed` (safe to re-run). All seeded logins use `password123`.
4. Add four throwaway pending accounts and mark one core file as failed:

   ```sh
   bin/rails runner '
     4.times { |i| User.find_or_create_by!(email: "walkthrough-#{i + 1}@example.org") { |u|
       u.name = "Walkthrough Tester #{i + 1}"; u.password = "password123"; u.account_status = :pending_review } }
     CoreFile.find_by!(title: "Private TEI Document")
             .update_columns(processing_status: "failed", processing_error: "Walkthrough: simulated TAPAS-XQ timeout")
     project = Project.find_by!(title: "Private Demo Project")
     project.project_invitations.active.first ||
       project.project_invitations.create!(creator: User.find_by!(email: "owner@example.com"))'
   ```

5. `bin/rails server`, then open `http://localhost:3000`.

| Login | Used for |
|---|---|
| `outsider@example.com` | A non-admin, to check admin pages are blocked |
| `admin@example.com` | Everything else |

Approve and reject act on real accounts in your dev database, so only use them
on the `walkthrough-*` accounts. Reject deletes the account.

---

## 1. Non-admins can't open admin pages (AC-2)

1. Sign in as `outsider@example.com`, then go to `http://localhost:3000/admin/users`.
2. **Expect:** you land on the home page with "Access denied."

![Non-admin redirected with Access denied](admin_pages/01_non_admin_denied.png)

## 2. The admin layout (AC-1)

1. Sign out, sign in as `admin@example.com`, go to `http://localhost:3000/admin`.
2. **Expect:** the Projects list, with **Projects** highlighted in the sidebar.
   In the browser's developer tools, the Console shows no errors, and the page
   source has a `<script type="importmap">` and no `administrate` script.

![Admin projects list](admin_pages/02_admin_projects_index.png)

## 3. Users list: sort arrows, filter buttons, search, pagination (AC-3d, AC-4, AC-4a, AC-4b)

1. Click **Users** in the sidebar.
2. **Expect:** 20 users per page, a faint ↕ next to each of the 6 column
   headings, a **Filter:** row with **Admin** and **Active** buttons, and no
   "New user" button.

   ![Users list](admin_pages/03a_users_index.png)

3. Click the **Name** heading, then the **Admin** filter button.
4. **Expect:** Name shows a solid ▲, the Admin button is filled in, the search
   box reads `admin:`, and only admin accounts are listed.

   ![Sorted by name with the Admin filter on](admin_pages/03b_users_sorted_admin_filter.png)

5. Click **Admin** again.
6. **Expect:** the full list is back, still sorted by name.
7. Type `example.org` in the search box and press Enter.
8. **Expect:** only the four `walkthrough-*` accounts.

   ![Text search](admin_pages/03c_users_text_search.png)

9. Clear the search (the ⓧ in the box) and go to page 2 with the page links at the bottom.
10. **Expect:** another 20 users and working page links.

    ![Pagination](admin_pages/03d_users_pagination.png)

## 4. A user's view and edit pages (AC-3, AC-3a, AC-3c, AC-7)

1. Search `walkthrough-4` and click the email.
2. **Expect:** sign-in times and IPs are shown; there is no encrypted password,
   reset password token, or remember-me timestamp.

   ![User view page](admin_pages/04a_user_show.png)

3. Click **Edit**.
4. **Expect:** Account status is a dropdown (pending_review / active). The Image
   File section says "Optional. Leave every field blank to save without an
   image." and its fields have no required stars.

   ![User edit form](admin_pages/04b_user_edit.png)

5. Set Institution to `Walkthrough University`, leave the image fields blank, click **Update User**.
6. **Expect:** "User was successfully updated." and the new institution.

   ![User updated](admin_pages/04c_user_updated.png)

7. Click **Destroy**, then **Cancel** in the prompt.
8. **Expect:** an "Are you sure?" prompt; after Cancel the user is still there.

## 5. New Account Review: per-row and bulk actions (AC-5, AC-6, AC-7, AC-8, AC-10)

This is the page whose bug started this work: with any rows ticked, the first
row's **Approve** button approved every ticked row.

1. Click **New Account Review** in the sidebar.
2. **Expect:** New Account Review is highlighted (not Users). Nadia Newcomer's
   row shows **Public Demo Project** under "Invited to"; your other pending
   accounts say "Direct sign-up (no invitation)".

   ![Account review page](admin_pages/05a_review_queue.png)

3. Tick the boxes for `walkthrough-2` and `walkthrough-3`.

   ![Two rows ticked](admin_pages/05b_two_ticked_before_row_approve.png)

4. Click **Approve** on the `walkthrough-1` row.
5. **Expect:** the prompt reads "Approve Walkthrough Tester 1's account and
   notify them by email?" Accept it. The flash names only Walkthrough Tester 1,
   and `walkthrough-2` and `walkthrough-3` are **still in the list**.

   ![Row approve acted on that row only](admin_pages/05c_row_approve_only_that_row.png)

6. Tick the box in the table header.
7. **Expect:** every row is ticked. Untick the header box; every row clears.

   ![Select all](admin_pages/05d_select_all.png)

8. Tick `walkthrough-2` and `walkthrough-3`, click **Approve Selected**.

   ![Two rows ticked for bulk approve](admin_pages/05e_two_ticked_for_bulk_approve.png)

9. **Expect:** the prompt reads "Approve all selected accounts and notify them
   by email?" Accept it. The flash says "2 account(s) are now active" and both
   rows are gone. `http://localhost:3000/letter_opener` shows approval emails
   for walkthrough 1, 2 and 3.

   ![Bulk approved](admin_pages/05f_bulk_approved.png)

10. Tick `walkthrough-4`, click **Reject Selected**.
11. **Expect:** the prompt reads "Reject and delete all selected accounts? They
    will not be notified." Accept it. The flash says "1 account(s) were rejected
    and removed." No email is sent.

    ![Bulk rejected](admin_pages/05g_bulk_rejected.png)

## 6. Invitation links (AC-7, AC-8)

1. Click **Invitation Links** in the sidebar.
2. **Expect:** Invitation Links is highlighted; links for Public Demo Project
   and Private Demo Project are listed.

   ![Invitation links](admin_pages/06a_invitation_links.png)

3. Click **Revoke** on the **Private Demo Project** row (leave the Public one; it's the seeded link).
4. **Expect:** a "Revoke this invitation link?" prompt; after accepting,
   "Invitation revoked." and only the Public Demo Project link remains.

   ![Invitation revoked](admin_pages/06b_invitation_revoked.png)

## 7. Projects and collections (AC-3, AC-3b, AC-3e)

1. Go to **Projects**, search `Public Demo`, open **Public Demo Project**.
2. **Expect:** Projects stays highlighted. The page lists the project's
   collections, core files, members and users, each linked to its own admin page.

   ![Project view page](admin_pages/07a_project_show.png)

3. Click **Edit**.
4. **Expect:** depositor, title, description, institution, public, and the
   optional image fields. No lists of collections, core files, members or users.

   ![Project edit form](admin_pages/07b_project_edit.png)

5. Open **Collections**, find **Public Demo Collection**, click **Edit**.
6. **Expect:** depositor, project, title, description, public, and image fields.
   No core files list.

   ![Collection edit form](admin_pages/07c_collection_edit.png)

## 8. Core files: filter, retry processing, collections picker (AC-3e, AC-4b, AC-8)

1. Open **Core Files** and click the **Processing failed** filter button.
2. **Expect:** only **Private TEI Document**.

   ![Processing failed filter](admin_pages/08a_core_files_processing_failed_filter.png)

3. Open **Private TEI Document**.
4. **Expect:** Edit, **Retry Processing** and Destroy buttons, and a
   **Processing Error** panel reading "Walkthrough: simulated TAPAS-XQ timeout".

   ![Failed core file](admin_pages/08b_core_file_failed_show.png)

5. Click **Edit**.
6. **Expect:** a **Collections** multi-select with **Private Demo Collection** selected.

   ![Core file collections picker](admin_pages/08c_core_file_edit_collections.png)

7. Go back to the file's page and click **Retry Processing**.
8. **Expect:** a "Re-submit this file to TAPAS-XQ?" prompt; after accepting,
   "File re-queued for processing."

   ![Retry submitted](admin_pages/08d_core_file_retry_submitted.png)

9. Reload the page.
10. **Expect (without TAPAS-XQ running):** the retry really ran, so the error
    panel now shows the new failure, "Cannot connect to TAPAS-XQ: Failed to open
    TCP connection to localhost:8080". With TAPAS-XQ running, the file processes instead.

    ![New error after retry](admin_pages/08e_core_file_retry_new_error.png)

## 9. Pages without sidebar links (AC-3, AC-3f, AC-3g)

1. Go to `http://localhost:3000/admin/project_members` and click **Edit** on any row.
2. **Expect:** **Role** is a dropdown of `contributor` / `owner`.

   ![Project member role dropdown](admin_pages/09a_project_member_role_dropdown.png)

3. Go to `http://localhost:3000/admin/image_files`.
4. **Expect:** the list loads with no "New image file" button.

   ![Image files, no New button](admin_pages/09b_image_files_no_new_button.png)

5. Go to `http://localhost:3000/admin/collection_core_files` and `http://localhost:3000/admin/view_packages`.
6. **Expect:** both load (view packages may be empty).

   ![Collection core files](admin_pages/09c_collection_core_files.png)
