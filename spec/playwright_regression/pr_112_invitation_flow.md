# Invitation flow — Playwright regression spec

Origin: PR #112 (`membership-invite-workflow`), 2026-07-21.
Covers: the full project-invitation workflow — existing-user acceptance, new-to-TAPAS registration with admin vetting (approve and reject paths), owner confirmation, link revocation, and the project-deletion cascade this branch also touches.

Prerequisites: Solr running and reachable at `http://localhost:8983/solr/#/tapas-core`; `bin/rails db:seed` run (safe to re-run); dev server up. Seeded accounts (password `password123` for all):

| Login | What it's for |
|---|---|
| `owner@example.com` | Owns the demo projects — generate/revoke invitation links, confirm/dismiss pending members |
| `contributor@example.com` | Contributor on both demo projects; owns one of their own |
| `outsider@example.com` | No memberships — existing user accepting an invite |
| `pending-vetting@example.com` | Already pending, waiting in the admin review queue |
| `pending-owner@example.com` | Already pending, waiting on owner confirmation |
| `admin@example.com` | Admin panel + membership review queue |

---

## Scenario 1 — New-to-TAPAS registrant is routed to admin vetting, not straight to owner

1. Sign in as `owner@example.com`, open the Public Demo Project page, copy the invitation link under "Invitation Links."
2. Sign out, open the link in a fresh browser context, sign up with a brand-new account.
3. Accept the invitation.
4. **Assert:** the confirmation message states the request is pending **admin** review (not owner review) — this is the new-to-TAPAS path.

## Scenario 2 — Admin approval notifies the owner

1. Sign in as `admin@example.com`, navigate to `/admin/project_members/review_queue`.
2. **Assert:** the registrant from Scenario 1 appears in the queue.
3. Click "Approve."
4. **Assert:** an email is delivered (via `letter_opener`) to the project owner requesting confirmation — check `tmp/letter_opener/<latest>/plain.html` for an "owner confirmation" subject line.
5. Sign in as `owner@example.com`, confirm the new member from the "Pending Members" list on the project page.
6. **Assert:** the member drops off the pending list after confirming.

## Scenario 3 — Existing user skips admin vetting entirely

1. Repeat the invite-accept flow signed in as `outsider@example.com`.
2. **Assert:** the flow goes straight to "pending owner confirmation" with no mention of admin review.
3. Sign in as `admin@example.com`, navigate to `/admin/project_members/review_queue`.
4. **Assert:** the `outsider@example.com` request never appears in this queue (existing users are never routed here).

## Scenario 4 — Owner's confirm-link email works when clicked cold, from any state (fixed 2026-07-21)

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

There is still no "Reject" affordance anywhere in the UI — the review queue
(`/admin/project_members/review_queue`) only exposes "Approve." The only way
to reject a registrant is the generic Administrate `Destroy` button on
`/admin/project_members/:id`, which has no status restriction. That's kept
in this scenario as a distinct sub-case: the confirm-link landing page now
degrades gracefully (a "no longer exists" message) instead of raising, if
the record is gone by the time the owner clicks.

1. Sign in as `owner@example.com`, copy a fresh invitation link.
2. Sign out, accept the invitation as an existing user with no admin-vetting step involved (e.g. `admin@example.com`, unrelated to the project).
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

## Scenario 5 — Link revocation

1. As `owner@example.com`, revoke an active invitation link.
2. **Assert:** the link immediately shows expired/revoked to anyone who opens it, with a message like "This invitation has been revoked. Please contact the project owner if you believe this is a mistake."

## Scenario 6 — Project deletion cascade (regression guard for the `dependent: :destroy` fix in this branch)

1. As `owner@example.com`, click "Delete Project" on a project that has collections/files and at least one invitation link (revoked or active) attached.
2. **Assert:** the confirmation prompt shows correct collection/file counts.
3. Confirm deletion.
4. **Assert:** deletion succeeds with a 200/redirect, not a 500 — this guards the `Project has_many :project_invitations` missing `dependent: :destroy` bug fixed in this branch (`417c29b`).

---

## Not covered here (deferred, not blocking per review)

- Cross-session redirect/caching bug (a signed-out session redirecting a different, newly-signed-in user to a stale revoked-invitation URL) — Ash's review flagged this as likely a client-side JS issue, probably not worth fixing given minimal JS usage. Not scripted here; revisit if that judgment changes.
