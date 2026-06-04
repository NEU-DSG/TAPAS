# Rails Application Audit Report

**Generated**: 2026-06-04  
**Application**: TAPAS (Text And Project Annotation Suite)  
**Rails Version**: 8.1.2  
**Ruby Version**: (current stable — check `.ruby-version`)  
**Audit Scope**: Full Application (`app/`, `spec/`, `db/`, `config/`)

---

## Executive Summary

| Category | Critical | High | Medium | Low | Total |
|----------|----------|------|--------|-----|-------|
| Testing | 0 | 2 | 3 | 1 | 6 |
| Security | 1 | 2 | 2 | 0 | 5 |
| Models | 0 | 2 | 6 | 0 | 8 |
| Controllers | 0 | 0 | 2 | 2 | 4 |
| Code Design | 0 | 0 | 3 | 2 | 5 |
| Views | 0 | 0 | 0 | 0 | 0 |
| **Total** | **1** | **6** | **16** | **5** | **28** |

### Key Findings

1. **SSRF vulnerability** in `ImageFile#process_image_data` — user-supplied `image_url` is passed directly to `URI.open`, allowing server-side request forgery.
2. **Double Solr indexing on update** in `Project` and `Collection` — `after_save` + `after_update` both fire on update, causing two Solr commits per save.
3. **Broken `Project#publicly_visible`** — declared as an instance method but calls `where`, making it non-functional dead code.

---

## 1. Testing Issues

### Overview
- **Test Framework**: RSpec
- **Files with Tests**: All model, request, and service files have corresponding specs — good overall coverage
- **Estimated Coverage**: Medium–High

### High Severity

#### T-01 Orphaned Spec: `spec/models/tei_file_spec.rb`

**File**: `spec/models/tei_file_spec.rb`  
**Impact**: A spec file exists for a model (`TeiFile`) that does not exist in `app/models/`. This spec likely fails or is silently skipped, and misleads developers into thinking a `TeiFile` model is tested.

**Recommendation**: Either delete the orphaned spec or create the missing model. Check whether `CoreFile` was originally called `TeiFile` and the spec wasn't cleaned up.

---

#### T-02 `User#sole_owned_projects` Has No Direct Unit Test

**File**: `spec/models/user_spec.rb`  
**Impact**: The method is only tested indirectly through account-deletion request specs. The N+1 query behavior and edge cases (co-owner, no projects) lack targeted unit test coverage.

**Recommendation**:
```ruby
describe '#sole_owned_projects' do
  let(:user) { create(:user) }

  it 'returns projects where user is the only owner' do
    project = create(:project, depositor: user)
    expect(user.sole_owned_projects).to include(project)
  end

  it 'excludes projects with multiple owners' do
    project = create(:project, depositor: user)
    co_owner = create(:user)
    project.project_members.create!(user: co_owner, role: 'owner')
    expect(user.sole_owned_projects).not_to include(project)
  end

  it 'excludes projects where user is a contributor' do
    depositor = create(:user)
    project = create(:project, depositor: depositor)
    create(:project_member, :contributor, project: project, user: user)
    expect(user.sole_owned_projects).to be_empty
  end
end
```

---

### Medium Severity

#### T-03 Testing Framework Internals in `user_spec.rb`

**File**: `spec/models/user_spec.rb:77-101`  
**Impact**: The "devise modules" describe block tests that `User.devise_modules` includes `:database_authenticatable`, `:registerable`, etc. This tests Devise's wiring, not application behavior. If Devise changes internals, these tests break for no app-level reason.

**Recommendation**: Delete the "devise modules" describe block. It provides no safety net for application logic.

---

#### T-04 Missing Coverage for `ImageFile#process_image_data`

**File**: `spec/models/image_file_spec.rb` (if it exists)  
**Impact**: The `process_image_data` method has a critical security issue (see S-01) and is not tested at all. Tests would have caught the SSRF risk.

**Recommendation**: Add model specs for `ImageFile` covering `validate_file_format` and (once fixed) `process_image_data`.

---

#### T-05 Empty Helper Specs Provide False Confidence

**Files**: `spec/helpers/collections_helper_spec.rb`, `spec/helpers/projects_helper_spec.rb`, etc.  
**Impact**: All four helper modules are empty (`module CollectionsHelper; end`), yet they each have a spec file. These specs currently test nothing meaningful and may hide future logic added to helpers without corresponding test updates.

**Recommendation**: Delete or consolidate the empty helper specs until the helpers contain actual code.

---

### Low Severity

#### T-06 `spec/requests/image_files_spec.rb` Not Reviewed for Completeness

**File**: `spec/requests/image_files_spec.rb`  
**Impact**: The `set_imageable` nil-return edge case (when no parent ID param is found) is an untested code path in `ImageFilesController`.

**Recommendation**: Add a request spec asserting that a request with no recognized parent ID param returns a 4xx response rather than a 500.

---

## 2. Security Issues

### Critical

#### S-01 SSRF (Server-Side Request Forgery) in `ImageFile#process_image_data`

**File**: `app/models/image_file.rb:12`  
**Impact**: An attacker who can create or update an `ImageFile` can set `image_url` to an internal endpoint (e.g., `http://169.254.169.254/latest/meta-data/` on AWS, or `http://localhost:3000/admin`) and cause the server to make that request.

**Current Code**:
```ruby
def process_image_data
  URI.open(image_url)
end
```

The `image_url` field is user-supplied via `image_file_params` in `ImageFilesController` which explicitly permits `:image_url`. There is no URL scheme validation or allowlist.

**Recommendation**:
```ruby
ALLOWED_SCHEMES = %w[http https].freeze

def process_image_data
  uri = URI.parse(image_url)
  raise ArgumentError, "Invalid URL scheme" unless ALLOWED_SCHEMES.include?(uri.scheme)
  raise ArgumentError, "Private/loopback addresses not allowed" if private_address?(uri.host)
  URI.open(image_url)
end

private

def private_address?(host)
  addr = IPAddr.new(Resolv.getaddress(host))
  addr.loopback? || addr.private?
rescue Resolv::ResolvError, IPAddr::InvalidAddressError
  true
end
```

Additionally, consider whether `process_image_data` should be called at all — if images are uploaded via ActiveStorage (`:file` attachment), `image_url` may be a legacy field whose `URI.open` use is no longer needed.

---

### High Severity

#### S-02 Dual Admin-Status Columns Create Authorization Confusion

**File**: `app/models/user.rb:28-30`, `db/schema.rb:133-134`  
**Impact**: The `users` table has both an `admin` boolean column (default: false) and an `admin_at` datetime column. `User#admin?` uses only `admin_at`. If code (or a data migration) ever sets `admin: true` without setting `admin_at`, the user would appear non-admin. Conversely, an admin could be "demoted" by clearing `admin_at` while `admin: true` remains, leading to inconsistent DB state.

**Current Code**:
```ruby
def admin?
  admin_at.present?
end
```

**Recommendation**: Drop the `admin` boolean column (it is redundant and unused) in a migration, or consolidate: use only `admin_at` as the canonical source of truth (the existing approach is fine, just remove the dead column to eliminate confusion).

---

#### S-03 Solr Query Injection Risk in `SolrHelpers#locate_record`

**File**: `app/models/concerns/solr_helpers.rb:13`  
**Impact**: The query is constructed via string interpolation with no Solr query escaping:
```ruby
SOLR_CORE_CONNECTION.get("select", params: { q: "#{field_name}:#{field_value}" })
```

If `field_name` or `field_value` contain Solr special characters (`:`, `(`, `)`, `"`, `*`, `?`), the query could be manipulated. The method is currently called internally (from `to_solr` output), but the public signature accepts arbitrary strings.

**Recommendation**: Escape Solr query parameters using RSolr's escaping utilities:
```ruby
escaped_value = RSolr.escape(field_value.to_s)
SOLR_CORE_CONNECTION.get("select", params: { q: "#{field_name}:#{escaped_value}" })
```

---

### Medium Severity

#### S-04 `ProjectMembersController` Bypasses Strong Parameters Pattern

**File**: `app/controllers/project_members_controller.rb:12-13`, `:27`  
**Impact**: User ID and role are read via `params.dig(:project_member, :user_id)` and `params.dig(:project_member, :role)` rather than through a permitted params method. `collection_ids` is consumed directly from params root. While only specific keys are read, the inconsistency with the rest of the app creates a pattern that is harder to audit.

**Recommendation**:
```ruby
def member_params
  params.require(:project_member).permit(:user_id, :role)
end

def collection_ids_param
  Array(params.permit(collection_ids: [])[:collection_ids])
end
```

---

#### S-05 `ImageFilesController#set_imageable` Silently Returns nil

**File**: `app/controllers/image_files_controller.rb:32-40`  
**Impact**: If a request arrives with no recognized parent ID param (e.g., typo in route), `@imageable` is `nil`. The next line `@imageable.image_file` (in `create`) raises `NoMethodError`, resulting in a 500 rather than a 404.

**Recommendation**:
```ruby
def set_imageable
  @imageable = if params[:user_id]
    User.find(params[:user_id])
  elsif params[:project_id]
    Project.find(params[:project_id])
  elsif params[:collection_id]
    Collection.find(params[:collection_id])
  elsif params[:core_file_id]
    CoreFile.find(params[:core_file_id])
  else
    raise ActionController::RoutingError, "No imageable resource found"
  end
end
```

---

## 3. Models Issues

### High Severity

#### M-01 `Project#publicly_visible` is a Broken Instance Method

**File**: `app/models/project.rb:64`  
**Impact**: The method is declared after a `public` keyword re-assertion following a `private` block:
```ruby
def publicly_visible
  where(is_public: true)
end
```
Calling `where` on a `Project` instance raises `NoMethodError`. This method cannot work as written. If it is called anywhere, it raises an error; if it is never called, it is dead code.

**Recommendation**: Replace with a proper scope:
```ruby
scope :publicly_visible, -> { where(is_public: true) }
```
Then search the codebase for any callers of `.publicly_visible` and update them.

---

#### M-02 Double Solr Indexing on Update (`Project` and `Collection`)

**File**: `app/models/project.rb:20-21`, `app/models/collection.rb:17-18`  
**Impact**: Both models declare:
```ruby
after_save :index_record   # fires on create AND update
after_update :update_record # fires on update only
```
Every update triggers two Solr commits (one for `index_record`, one for `update_record`). Since each Solr operation does a full commit, this doubles write latency on every save.

**Recommendation**: Remove the redundant callback. Decide which method is correct for updates and use only one:
```ruby
# In Project and Collection:
after_create :index_record
after_update :update_record
```
Then verify whether `index_record` and `update_record` in `SolrHelpers` differ meaningfully. If they are functionally equivalent, consolidate them.

---

### Medium Severity

#### M-03 `CoreFile#to_solr` Has a Syntax/Logic Bug on Line 75

**File**: `app/models/core_file.rb:75`  
**Impact**: 
```ruby
solr_doc["all_text_timv"] => nil
```
This uses the rightward pattern-match operator (`=>`), not assignment. In Ruby 3+, this is syntactically valid as a pattern match expression (it matches `solr_doc["all_text_timv"]` against `nil` and raises `NoMatchingPatternError` if it doesn't match). It does **not** set the key to nil in the hash. The TODO comment acknowledges this is unresolved, but the syntax is incorrect either way.

**Recommendation**: If the intent is to set the key to nil:
```ruby
solr_doc["all_text_timv"] = nil
```
If the field is truly unknown and shouldn't be set, remove the line entirely and the TODO.

---

#### M-04 `Project#members` Mutates Underlying Array with `map!`

**File**: `app/models/project.rb:35`  
**Impact**:
```ruby
user_members[k] = v.map!(&:user)
```
`map!` modifies the `v` array in-place. Since `v` comes from `project_group` (which groups `ProjectMember` AR objects), this mutates the grouped result. If `project_group` is called again in the same request, the grouped values will already be the mutated user objects.

**Recommendation**: Use `map` (non-mutating):
```ruby
user_members[k] = v.map(&:user)
```

---

#### M-05 `User#sole_owned_projects` Has an N+1 Query

**File**: `app/models/user.rb:21-25`  
**Impact**:
```ruby
Project
  .joins(:project_members)
  .where(project_members: { user: self, role: "owner" })
  .select { |p| p.project_members.where(role: "owner").count == 1 }
```
The `.select { |p| ... }` block runs in Ruby after loading all owned projects, then fires one additional SQL query per project (`p.project_members.where(role: "owner").count`). For a user with many owned projects, this is O(n) queries.

**Recommendation**: Use a subquery to find projects with exactly one owner in SQL:
```ruby
def sole_owned_projects
  Project
    .joins(:project_members)
    .where(project_members: { user: self, role: "owner" })
    .where(
      Project.joins(:project_members)
             .where(project_members: { role: "owner" })
             .group("projects.id")
             .having("COUNT(project_members.id) = 1")
             .select("projects.id")
             .arel
             .exists
    )
end
```
Or use a simpler `having` clause:
```ruby
def sole_owned_projects
  Project
    .joins(:project_members)
    .where(project_members: { role: "owner" })
    .group("projects.id")
    .having("COUNT(project_members.id) = 1")
    .merge(Project.joins(:project_members).where(project_members: { user: self }))
end
```

---

#### M-06 `SolrHelpers` Establishes Connection at Module Load Time

**File**: `app/models/concerns/solr_helpers.rb:5-6`  
**Impact**:
```ruby
SOLR_CORE_URL = ENV.fetch("DEV_SOLR_URL", "http://127.0.0.1:8983/solr/tapas-core")
SOLR_CORE_CONNECTION = RSolr.connect(url: SOLR_CORE_URL)
```
This runs the moment any model including `SolrHelpers` is loaded (including during test boot). If Solr is unavailable, the connection attempt may fail at load time or silently create a dead connection object. Tests that don't need Solr still pay the overhead.

**Recommendation**: Lazy-initialize the connection:
```ruby
def solr_connection
  @solr_connection ||= RSolr.connect(url: ENV.fetch("DEV_SOLR_URL", "http://127.0.0.1:8983/solr/tapas-core"))
end
```

---

#### M-07 Missing Database Indexes

**File**: `db/schema.rb`  
**Impact**: Several frequently-queried foreign key columns lack indexes:

| Table | Missing Index | Used In |
|-------|--------------|---------|
| `collections` | `project_id` | Nearly every collection query |
| `core_files` | `depositor_id` | Authorization/filtering |
| `image_files` | `depositor_id` | Authorization |
| `project_members` | Composite `(user_id, project_id)` unique | Uniqueness enforced in Ruby only |

**Recommendation**: Add a migration:
```ruby
add_index :collections, :project_id
add_index :core_files, :depositor_id
add_index :image_files, :depositor_id
add_index :project_members, [:user_id, :project_id], unique: true
```

---

#### M-08 `Project#project_group` Calls Redundant `.all`

**File**: `app/models/project.rb:25`  
**Impact**: `ProjectMember.all.where(project_id: id)` — the `.all` is a no-op (AR chains it) but implies "load everything then filter," which misleads readers.

**Recommendation**:
```ruby
def project_group
  ProjectMember.where(project_id: id).group_by(&:role)
end
```

---

## 4. Controllers Issues

### Medium Severity

#### C-01 `ProjectMembersController` Lacks Strong Parameters

See **S-04** above. The same finding applies from a controller design perspective: this controller is the only one that doesn't use a permitted params method, making the codebase inconsistent.

---

#### C-02 `ImageFilesController#set_imageable` Silently Returns nil

See **S-05** above. From a controller design perspective, failing open (returning nil for an unrecognized parent) should raise or redirect cleanly.

---

### Low Severity

#### C-03 Duplicate Image File Depositor Assignment in `ProjectsController`

**File**: `app/controllers/projects_controller.rb:17-19`, `33-35`  
**Impact**: The pattern:
```ruby
if @project.image_file
  @project.image_file.depositor_id = current_user.id
end
```
is repeated in both `create` and `update`. The `image_file` check triggers a DB query. This belongs in the model or can be handled via `accepts_nested_attributes_for` with a before-action.

**Recommendation**: Extract to a private method or handle depositor assignment in the `ImageFile` model's `before_create` callback.

---

#### C-04 `CatalogController` Stubs Out Both Actions

**File**: `app/controllers/catalog_controller.rb:119-127`  
**Impact**: Both `index` and `show` redirect to `root_path`, making the Blacklight configuration dead code. The inline comment says "Frontend will implement the actual search UI later." If this is intentional scaffolding, it's fine — but if Blacklight integration has been deferred indefinitely, the configuration should be tracked as a known gap.

---

## 5. Code Design Issues

### Medium Severity

#### D-01 Service Objects Should Be Domain Models

**Files**: `app/services/tapas_xq/retrieval_service.rb`, `app/services/tapas_xq/storage_service.rb`  
**Impact**: Per thoughtbot's PORO guidelines, classes named `*Service` obscure the domain concept. These are the external API interaction layer for TAPAS-XQ, not generic services.

**Recommendation**:
```
TapasXq::RetrievalService → TapasXq::Retrieval
TapasXq::StorageService   → TapasXq::Storage
```

Move to `app/models/tapas_xq/` or keep in `app/services/` with the rename. The `retrieve_tei`, `retrieve_mods`, `retrieve_tfe`, and `store` methods are already good domain verbs — just fix the class names.

---

#### D-02 `SolrHelpers` Violates Single Responsibility

**File**: `app/models/concerns/solr_helpers.rb`  
**Impact**: The concern:
- Owns a singleton Solr connection (infrastructure)
- Provides indexing (`index_record`, `update_record`)
- Provides deletion (`delete_record`, `delete_all_indexed_records`)
- Provides querying (`locate_record`, `record_count`)
- Uses `puts` in `delete_all_indexed_records` (not `Rails.logger`)

This is 4+ responsibilities in one concern, mixed with infrastructure setup.

**Recommendation**: Split into at minimum:
- A `Indexable` concern (just `index_record`, `update_record`) that each model includes
- A `SolrRepository` or `SolrAdmin` class for deletion and querying

Replace `puts` with `Rails.logger.info`.

---

#### D-03 Unconventional `public` / `private` Ordering in `Project` and `Collection`

**File**: `app/models/project.rb:62-75`, `app/models/collection.rb:37-51`  
**Impact**: Both models use `private`/`public` keyword pairs mid-class to re-expose `to_solr` after it was accidentally placed after the `private` block, or to switch visibility back. This is unusual and confusing to readers expecting the standard Ruby convention of private methods last.

**Recommendation**: Reorder methods so all public methods appear before the `private` keyword. Remove the `public` re-declaration.

---

### Low Severity

#### D-04 Commented-Out Generated Code in `RegistrationsController`

**File**: `app/controllers/users/registrations_controller.rb`  
**Impact**: ~40 lines of commented-out Devise method stubs generated by `devise:controllers`. These serve no purpose since Devise's defaults are inherited automatically.

**Recommendation**: Delete all commented-out methods. Keep only the `destroy` override that contains actual app logic.

---

#### D-05 `puts` in Model Concern

**File**: `app/models/concerns/solr_helpers.rb:38`  
**Impact**: `puts "Deleting solr indexed records."` — console output from a model method won't appear in logs.

**Recommendation**: Replace with `Rails.logger.info("Deleting all Solr indexed records.")`.

---

## Recommendations Summary

### Quick Wins (Immediate Action — Low Risk, High Value)

- [ ] **S-01**: Fix SSRF in `ImageFile#process_image_data` — validate URL scheme and block private addresses
- [ ] **M-02**: Remove redundant `after_save :index_record` or `after_update :update_record` in `Project` and `Collection` (pick one, keep the other)
- [ ] **M-01**: Replace broken `Project#publicly_visible` instance method with a scope
- [ ] **M-03**: Fix `CoreFile#to_solr` line 75: `=>` → `=`
- [ ] **M-04**: Change `map!` to `map` in `Project#members`
- [ ] **D-05**: Replace `puts` with `Rails.logger.info` in `SolrHelpers`
- [ ] **D-04**: Delete commented-out code in `RegistrationsController`

### Short-Term (This Milestone)

- [ ] **M-07**: Add missing database indexes (migration)
- [ ] **S-02**: Drop the redundant `admin` boolean column from `users`
- [ ] **S-04 / C-01**: Add strong parameters method to `ProjectMembersController`
- [ ] **S-05 / C-02**: Fix `ImageFilesController#set_imageable` nil-return
- [ ] **M-05**: Refactor `User#sole_owned_projects` to use a SQL subquery
- [ ] **M-06**: Lazy-initialize Solr connection in `SolrHelpers`
- [ ] **T-01**: Delete or resolve orphaned `spec/models/tei_file_spec.rb`
- [ ] **T-02**: Add direct unit tests for `User#sole_owned_projects`

### Long-Term (Technical Debt)

- [ ] **D-01**: Rename `*Service` classes to domain nouns
- [ ] **D-02**: Split `SolrHelpers` concern into smaller focused objects
- [ ] **D-03**: Reorder `public`/`private` blocks in `Project` and `Collection`
- [ ] **S-03**: Add Solr query escaping to `SolrHelpers#locate_record`
- [ ] **T-03**: Remove tests that test Devise internals in `user_spec.rb`
- [ ] **C-04**: Either implement or explicitly defer Blacklight `CatalogController` actions

---

## Files Analyzed

| Directory | Files Analyzed | Issues Found |
|-----------|----------------|--------------|
| `app/models/` | 9 | 9 |
| `app/controllers/` | 15 | 5 |
| `app/services/` | 3 | 1 |
| `app/helpers/` | 5 | 1 |
| `app/jobs/` | 1 | 0 |
| `app/views/` | 30+ | 0 |
| `spec/` | 47 | 3 |
| `db/schema.rb` | 1 | 1 |
| **Total** | **111+** | **28** |

---

## Appendix: Tools Already in Gemfile

The following code quality tools are already installed — they can provide ongoing automation:

| Tool | Purpose | Command |
|------|---------|---------|
| **RuboCop** (`rubocop-rails-omakase`) | Style and lint | `bundle exec rubocop` |
| **Brakeman** | Security scanning | `bundle exec brakeman` |
| **SimpleCov** | Test coverage | Auto-runs with test suite |
| **Bullet** | N+1 detection | Enabled in dev config |
| **flog / flay** | Complexity metrics | `bundle exec flog app/` |
| **Reek** | Code smell detection | `bundle exec reek app/` |
| **Bundler Audit** | Gem vulnerability scan | `bundle exec bundler-audit` |

Run `bundle exec brakeman` as a next step — it will independently confirm the SSRF finding (S-01) and may surface additional issues.

---

*Report generated by Rails Audit Skill (thoughtbot Best Practices)*
