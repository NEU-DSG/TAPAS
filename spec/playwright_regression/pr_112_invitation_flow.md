# Invitation flow — Playwright regression spec

Origin: PR #112 (`membership-invite-workflow`), 2026-07-21. Updated 2026-07-22
for the account-level registration vetting change (Card 1.53): vetting moved
from a per-membership flag (`needs_admin_vetting` on `project_members`, now
dropped) to a per-account gate (`account_status` on `users`) that blocks
sign-in entirely until an admin reviews the account. The old
`/admin/project_members/review_queue` is gone; the queue is now
`/admin/users/review_queue` ("New Account Review"), listing accounts, not
memberships.

Covers: the full project-invitation workflow — existing-user acceptance,
new-to-TAPAS registration with account-level vetting (approve and reject
paths), owner confirmation, link revocation, and the project-deletion
cascade this branch also touches.

Prerequisites: Solr running and reachable at `http://localhost:8983/solr/#/tapas-core`; `bin/rails db:seed` run (safe to re-run); dev server up. Seeded accounts (password `password123` for all):

| Login | What it's for |
|---|---|
| `owner@example.com` | Owns the demo projects — generate/revoke invitation links, confirm/dismiss pending members |
| `contributor@example.com` | Contributor on both demo projects; owns one of their own |
| `outsider@example.com` | No memberships — existing user accepting an invite |
| `pending-vetting@example.com` | Account blocked, waiting in the admin account review queue — **cannot sign in yet** |
| `pending-owner@example.com` | Active account, pending membership waiting on owner confirmation |
| `admin@example.com` | Admin panel + account review queue |

---

## Scenario 1 — New-to-TAPAS registrant is blocked at signup, not routed through invite-accept at all

1. Sign in as `owner@example.com`, open the Public Demo Project page, copy the invitation link under "Invitation Links."
2. Sign out, open the link in a fresh browser context, click "Sign Up" and register a brand-new account.
3. **Assert:** the confirmation message states the account is pending **admin review** and you are NOT signed in — there is no "Accept Invitation" step available yet, because the account can't sign in.
4. Attempt to sign in immediately with the new account's credentials.
5. **Assert:** sign-in fails with "Your account is awaiting admin review. You'll receive an email once it has been approved."

## Scenario 2 — Admin approval activates the account and lets the registrant pick up the invitation

1. Sign in as `admin@example.com`, navigate to `/admin/users/review_queue`.
2. **Assert:** the registrant from Scenario 1 appears in the queue, with the Public Demo Project shown in the "Invited to" column (not "Direct sign-up").
3. Click "Approve."
4. **Assert:** an "Your TAPAS account has been approved" email is delivered (via `letter_opener`) to the registrant, containing a link back to the invitation.
5. Sign in as the now-approved registrant, follow the invitation link from the email, and click "Accept Invitation."
6. **Assert:** the confirmation message now states the request is pending **owner** confirmation, and an owner-confirmation email is delivered to `owner@example.com`.
7. Sign in as `owner@example.com`, confirm the new member from the "Pending Members" list on the project page.
8. **Assert:** the member drops off the pending list after confirming.

## Scenario 3 — Rejection is silent

1. Repeat step 2 of Scenario 1 to create a second blocked registrant.
2. Sign in as `admin@example.com`, navigate to `/admin/users/review_queue`, and click "Reject" on that registrant.
3. **Assert:** the row disappears from the queue with no email-related notice.
4. Check `letter_opener` (`/letter_opener`) and confirm no email was delivered to the rejected address.
5. Attempt to sign in as the rejected account.
6. **Assert:** sign-in fails with an invalid-credentials message (not the pending-review message) — the account no longer exists.

## Scenario 4 — Existing user skips account vetting entirely

1. Repeat the invite-accept flow signed in as `outsider@example.com` (already an active, established account).
2. **Assert:** the flow goes straight to "pending owner confirmation" with no admin step or account-review mention at any point.
3. Sign in as `admin@example.com`, navigate to `/admin/users/review_queue`.
4. **Assert:** `outsider@example.com` never appears in this queue — only newly registered, not-yet-reviewed accounts show up here.

## Scenario 5 — Owner's confirm-link email works when clicked cold, from any state (fixed 2026-07-21)

Updated 2026-07-21: the original framing of this scenario was wrong. It's
not the admin-destroy path that breaks the link — the link was broken for
*everyone, always*, regardless of any destroy/reject action. Root cause:
`app/views/invitation_mailer/owner_confirmation_request.html.erb` rendered
`link_to "Confirm Membership", @confirm_url, method: :patch` — a plain
`<a href>` whose `method: :patch` only works via Rails UJS JS rewriting the
click into a real PATCH. Email clients don't run that JS, so following the
link from an actual email was always a GET against a PATCH-only route
(`patch :confirm` in `config/routes.rb`), 404ing on *every* click, on *any*
record, destroyed or not. Reproduced on a completely untouched record with
no admin/destroy involvement at all to confirm this before fixing it.

Fix: added a GET-safe landing route/action (`confirm_show`, routed as
`get :confirm, action: :confirm_show, as: :confirm_landing`) that renders a
page with a real `button_to` form — the same no-JS-required pattern the
in-app "Confirm" button already used — which performs the actual PATCH.
The mailer now links to this GET route instead of the PATCH-only one.

There is still no "Reject" affordance for a *membership* anywhere in the UI —
the only way to remove a pending member is the generic Administrate
`Destroy` button on `/admin/project_members/:id`, which has no status
restriction. (Account-level rejection, added 2026-07-22, is a separate
affordance in the new `/admin/users/review_queue` — see Scenario 3.) That's
kept in this scenario as a distinct sub-case: the confirm-link landing page
now degrades gracefully (a "no longer exists" message) instead of raising,
if the record is gone by the time the owner clicks.

1. Sign in as `owner@example.com`, copy a fresh invitation link.
2. Sign out, accept the invitation as an existing user with no account-vetting step involved (e.g. `admin@example.com`, unrelated to the project).
3. **Assert:** an owner-confirmation email is delivered containing a link shaped `/projects/:id/project_members/:id/confirm`.
4. Sign in as `owner@example.com`, navigate directly to that link (cold — no prior page load, mirroring an actual email client's plain GET).
5. **Assert (previously FAILED, now PASSES — verified 2026-07-21):** HTTP 200, a "Confirm Membership" landing page with a real form/button, not a routing exception.
6. Click the page's "Confirm Membership" button.
7. **Assert:** redirect to the project page with a flash confirming the member, and the member drops off the pending list.

### Sub-case — destroyed record shows a graceful message, not a crash

1. Repeat steps 1-3 above for a second registrant.
2. Navigate to `/admin/project_members/:id` for that record and click "Destroy" before the owner confirms.
3. As `owner@example.com`, follow the confirm link captured in step 3 of the main scenario.
4. **Assert:** HTTP 200 with a "no longer exists" message, not a raw `ActiveRecord::RecordNotFound`/routing exception.

## Scenario 6 — Link revocation

1. As `owner@example.com`, revoke an active invitation link.
2. **Assert:** the link immediately shows expired/revoked to anyone who opens it, with a message like "This invitation has been revoked. Please contact the project owner if you believe this is a mistake."

## Scenario 7 — Project deletion cascade (regression guard for the `dependent: :destroy` fix in this branch)

1. As `owner@example.com`, click "Delete Project" on a project that has collections/files and at least one invitation link (revoked or active) attached.
2. **Assert:** the confirmation prompt shows correct collection/file counts.
3. Confirm deletion.
4. **Assert:** deletion succeeds with a 200/redirect, not a 500 — this guards the `Project has_many :project_invitations` missing `dependent: :destroy` bug fixed in this branch (`417c29b`).

---

## Not covered here (deferred, not blocking per review)

- Cross-session redirect/caching bug (a signed-out session redirecting a different, newly-signed-in user to a stale revoked-invitation URL) — Ash's review flagged this as likely a client-side JS issue, probably not worth fixing given minimal JS usage. Not scripted here; revisit if that judgment changes.
