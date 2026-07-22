# Development seed data for manual UI testing.
#
# A small, deterministic world with known logins, scaled down from
# lib/tasks/dummy_data_generator.rake (which builds a large randomized
# dataset). Idempotent: safe to re-run with `bin/rails db:seed`.
#
# Requires Solr to be running — Project/Collection/CoreFile index themselves
# on save and will raise if it isn't reachable.

unless Rails.env.development?
  puts "Seeds are development-only manual-testing data; nothing to do in #{Rails.env}."
  return
end

require "faker"

begin
  SolrHelpers.record_count
rescue StandardError => e
  abort <<~MSG
    Solr isn't reachable at #{SolrHelpers::SOLR_CORE_URL} (#{e.class}: #{e.message}).
    Records index themselves to Solr on save, so seeding can't proceed without it.
    Start Solr and re-run `bin/rails db:seed`.
  MSG
end

SEED_PASSWORD = "password123"

def seed_user(email, name, admin: false, account_status: :active)
  User.find_or_create_by!(email: email) do |user|
    user.name = name
    user.bio = Faker::Lorem.paragraph
    user.password = SEED_PASSWORD
    user.account_status = account_status
    user.admin_at = Time.current if admin
  end
end

# Borrowed from lib/tasks/dummy_data_generator.rake — minimal valid TEI so
# core files can be created without fetching anything over the network.
def generated_tei(title)
  <<~XML
    <?xml version="1.0" encoding="UTF-8"?>
    <TEI xmlns="http://www.tei-c.org/ns/1.0">
      <teiHeader>
        <fileDesc>
          <titleStmt>
            <title>#{title}</title>
          </titleStmt>
          <publicationStmt>
            <p>Sample TEI document for #{title}</p>
          </publicationStmt>
          <sourceDesc>
            <p>Generated seed data</p>
          </sourceDesc>
        </fileDesc>
      </teiHeader>
      <text>
        <body>
          <p>This is a sample TEI document.</p>
        </body>
      </text>
    </TEI>
  XML
end

def seed_core_file(collection:, title:, depositor:, is_public:, ography_type: nil)
  existing = CoreFile.joins(:collections).find_by(title: title, collections: { id: collection.id })
  return existing if existing

  core_file = CoreFile.new(
    title: title,
    description: Faker::Book.genre,
    depositor: depositor,
    collections: [ collection ],
    is_public: is_public,
    ography_type: ography_type,
    tei_authors: Faker::Book.author
  )

  unless ography_type
    core_file.tei_file.attach(
      io: StringIO.new(generated_tei(title)),
      filename: "#{title.parameterize}.xml",
      content_type: "application/xml"
    )
  end

  core_file.save!
  core_file
end

puts "Seeding users..."
admin       = seed_user("admin@example.com",       "Ada Admin", admin: true)
owner       = seed_user("owner@example.com",       "Olivia Owner")
contributor = seed_user("contributor@example.com", "Carl Contributor")
outsider    = seed_user("outsider@example.com",    "Odette Outsider")
known_user  = seed_user("pending-owner@example.com",   "Kip Knownuser")

puts "Seeding projects..."
# assign_default_owner makes the depositor an active owner automatically.
public_project = Project.find_or_create_by!(title: "Public Demo Project") do |project|
  project.description = Faker::Lorem.paragraph
  project.institution = Faker::University.name
  project.depositor = owner
  project.is_public = true
end

private_project = Project.find_or_create_by!(title: "Private Demo Project") do |project|
  project.description = Faker::Lorem.paragraph
  project.institution = Faker::University.name
  project.depositor = owner
  project.is_public = false
end

# A project the contributor owns, so that login can exercise owner flows too.
contributor_project = Project.find_or_create_by!(title: "Contributor's Own Project") do |project|
  project.description = Faker::Lorem.paragraph
  project.institution = Faker::University.name
  project.depositor = contributor
  project.is_public = true
end

puts "Seeding memberships..."
[ public_project, private_project ].each do |project|
  ProjectMember.find_or_create_by!(project: project, user: contributor) do |member|
    member.role = "contributor"
    member.status = :active
  end
end

# Mid-flow invite state for the membership workflow: an established user
# awaiting owner confirmation (shows in the pending list on the project page).
ProjectMember.find_or_create_by!(project: public_project, user: known_user) do |member|
  member.role = "contributor"
  member.status = :pending
end

puts "Seeding invitation links..."
invitation = public_project.project_invitations.active.first ||
             public_project.project_invitations.create!(creator: owner)

# Mid-flow account-vetting state: a brand-new registrant blocked at signup,
# waiting in the admin account review queue, carrying the invitation they
# registered from. They have no ProjectMember row yet — account vetting
# happens before an invite can even be accepted.
new_reg = seed_user("pending-vetting@example.com", "Nadia Newcomer", account_status: :pending_review)
new_reg.update!(signup_invitation_token: invitation.token) if new_reg.signup_invitation_token.blank?

puts "Seeding collections..."
public_collection = Collection.find_or_create_by!(title: "Public Demo Collection", project: public_project) do |collection|
  collection.description = Faker::Lorem.sentence
  collection.depositor = owner
  collection.is_public = true
end

private_collection = Collection.find_or_create_by!(title: "Private Demo Collection", project: public_project) do |collection|
  collection.description = Faker::Lorem.sentence
  collection.depositor = owner
  collection.is_public = false
end

hidden_collection = Collection.find_or_create_by!(title: "Hidden Demo Collection", project: private_project) do |collection|
  collection.description = Faker::Lorem.sentence
  collection.depositor = owner
  collection.is_public = false
end

puts "Seeding core files (TEI processing runs in background jobs)..."
seed_core_file(collection: public_collection, title: "Public TEI Document",
               depositor: owner, is_public: true)
seed_core_file(collection: public_collection, title: "Contributor TEI Document",
               depositor: contributor, is_public: true)
seed_core_file(collection: public_collection, title: "Demo Personography",
               depositor: owner, is_public: true, ography_type: "personography")
seed_core_file(collection: private_collection, title: "Private TEI Document",
               depositor: owner, is_public: false)
seed_core_file(collection: hidden_collection, title: "Hidden TEI Document",
               depositor: owner, is_public: false)

invitation_link = Rails.application.routes.url_helpers.invitation_url(
  invitation.token, host: "localhost", port: 3000
)

puts <<~SUMMARY

  #{"=" * 72}
  Seed data ready. All accounts use password: #{SEED_PASSWORD}

    admin@example.com            admin (account review queue, admin panel)
    owner@example.com            owns Public + Private Demo Projects
    contributor@example.com      contributor on both; owns own project
    outsider@example.com         no memberships (sees public content only)
    pending-vetting@example.com  blocked account awaiting ADMIN review (cannot sign in yet)
    pending-owner@example.com    pending member awaiting OWNER confirmation

  Active invitation link for Public Demo Project:
    #{invitation_link}
  #{"=" * 72}
SUMMARY
