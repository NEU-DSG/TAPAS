namespace :dummy_data_generator do
  require "faker"
  require "net/http"
  require "open-uri"

  IMAGE_BASE_URL = ENV.fetch("IMAGE_BASE_URL", nil)
  RAW_TEI_URL = ENV.fetch("RAW_TEI_URL", nil)

  # Helper method to check queue adapter configuration
  desc "checks queue adapter configuration"
  task :check_queue_adapter => :environment do
    adapter = ActiveJob::Base.queue_adapter
    adapter_name = adapter.class.name

    puts "\n" + "=" * 80
    puts "Queue Adapter Check"
    puts "=" * 80

    case adapter_name
    when "ActiveJob::QueueAdapters::AsyncAdapter"
      puts "✓ Using AsyncAdapter (Development)"
      puts "  - Jobs process asynchronously in background threads"
      puts "  - No external workers required"
      puts "  - ActiveStorage file processing will happen automatically"
    when "ActiveJob::QueueAdapters::SolidQueueAdapter"
      puts "✓ Using Solid Queue (Production)"
      puts "  - Database-backed persistent job queue"
      puts "  - Make sure workers are running: bin/rails solid_queue:start"
      puts ""
      print "Are Solid Queue workers running? (y/N): "
      response = STDIN.gets.chomp.downcase
      unless response == "y" || response == "yes"
        puts "\nWarning: File processing may be delayed without workers."
        puts "Start workers with: bin/rails solid_queue:start"
        print "Continue anyway? (y/N): "
        continue = STDIN.gets.chomp.downcase
        unless continue == "y" || continue == "yes"
          puts "Aborted. Please start Solid Queue workers and try again."
          exit 1
        end
      end
    else
      puts "⚠ Using #{adapter_name}"
      puts "  - Custom queue adapter detected"
      puts "  - Ensure your workers are properly configured"
    end

    puts "=" * 80 + "\n"
  end

  def record_image(record, image_name = nil)
    url = "#{IMAGE_BASE_URL}"
    image_data = URI.open(url)
    image_name ||= "#{record.class}_#{record.__id__}"
    depositor_id = record.is_a?(User) ? record.id : record.depositor_id

    record_assoc_image_file = ImageFile.create!(
      title: image_name,
      depositor_id: depositor_id,
      imageable_type: record.class.name,
      imageable_id: record.id,
      file_format: image_data.content_type,
      image_url: url
    )

    # Attach the file to the ImageFile model (not directly to the record)
    record_assoc_image_file.file.attach(io: image_data, filename: record_assoc_image_file.title, content_type: record_assoc_image_file.file_format)
    record_assoc_image_file.save

    puts "Image file attached for #{record.class} #{record.id}"
  end

  # Create a given number of new projects.
  # If `num_projects` is not defined in ENV, 45 projects are created.
  def create_projects
    # Check the number of Projects we had before creating new ones.
    older_projects = Project.count
    # If the Rake task is called with an argument for "num_projects", use that value as the number of
    # projects to create. Integer() will throw an ArgumentError if the value can't be converted.
    num_projects = !ENV['num_projects'].nil? ? Integer(ENV['num_projects']) : 45
    # Keep track of new projects and their public and private status.
    new_project_ids = Array.new
    availability = Array.new

    num_projects.times do |i|
      # The first three projects are private. Otherwise, pick a number between 0 and 
      # 2. If the number is 2, the project is private.
      is_private = i < 3 ? true : Random.rand(3) == 2
      # Pick a number between 0 and 3. If the number is 3, generate an institution string.
      include_institution = Random.rand(4) == 3
      # Pick a number between 0 and 3. If the number is 3, add an image.
      include_image = Random.rand(4) == 3

      new_project = Project.create!(title: Faker::Company.bs,
                                    description: Faker::Lorem.paragraph,
                                    depositor_id: User.all.where(admin_at: nil).sample.id,
                                    is_public: !is_private,
                                    institution: include_institution ? Faker::University.name : nil
      )

      if include_image
        record_image(new_project)
      end

      new_project_ids.push(new_project.id)
      availability.push(is_private ? 'private' : 'public')
    end

    # Split the availability array into two: one for "private" and one for "public".
    availability = availability.partition { |p| p == 'private' }
    puts "Created #{ availability[0].length } private and #{ availability[1].length } public projects."

    # If the number of projects isn't what we expected, give a warning.
    if Project.count != num_projects + older_projects
      num_new = Project.count - older_projects
      warn "WARNING: #{num_new} projects created, expected #{num_projects + older_projects}"
    end

    # Output the new project IDs, so they can be used in other tasks.
    new_project_ids
  end

  # Create project members for a given array of project ids.
  # If no array is provided, all projects have members added.
  def create_project_members(project_ids = Project.all.ids)
    Project.find(project_ids).each do |project|
      # Populate a project's members from non-admins.
      available_users = User.all.select { |u| u.admin_at.nil? }.map(&:id)
      # The depositor should have already been added, so remove them from the pool.
      available_users.delete(project.depositor_id)
      num_contributors = Random.rand(13)   # 0 to 12
      num_owners = Random.rand(6)   # 0 to 5, plus the depositor

      if available_users.count < num_owners + num_contributors
        warn "WARNING: There aren't enough users available to fully populate project #{project.id}."
        warn "  Did you run the dummy_data_generator:non_admin_users task?"
      end

      # Project owner
      # - Has full edit access for the project
      # - Can create collections and core files
      # Create any additional owners (besides the depositor).
      num_owners_added = 0
      num_owners.times do
        user_id = available_users.sample
        if !user_id.nil?
          available_users.delete(user_id)
  
          ProjectMember.create!(project_id: project.id,
                                user_id: user_id,
                                role: "owner"
          )
          num_owners_added += 1
        end
      end

      # Project contributor
      # - Has access to a TAPAS project but is not an owner
      # - Can create core files but not collections
      num_contributors_added = 0
      num_contributors.times do
        user_id = available_users.sample
        if !user_id.nil?
          available_users.delete(user_id)
  
          ProjectMember.create!(project_id: project.id,
                                user_id: user_id,
                                role: "contributor"
          )
          num_contributors_added += 1
        end
      end

      puts "#{ProjectMember.where(project_id: project.id).count} project members in #{project.id}: #{project.title}"
      puts "    #{num_owners_added} project owners created (+ depositor)"
      puts "    #{num_contributors_added} contributors created"
    end
  end

  # Create collections for a given array of project ids.
  # If no array is provided, all projects have collections added.
  def create_collections(project_ids = Project.all.ids)
    Project.find(project_ids).each do |project|
      project_owners = project.owner.shuffle
      is_empty = Random.rand(101) >= 95  # Very low chance for a project to have 0 collections
      num_collections = is_empty ? 0 : 1 + Random.rand(10) # 0 to 10
      # Pick a number between 0 and 3. If the number is 3, add an image.
      include_image = Random.rand(4) == 3
      new_collections = 0

      num_collections.times do
        # If the project is public, the collection can be public or private.
        # If the project is private, the new collection must be too.
        visibility = project.is_public ? [true, false].sample : false

        collection = Collection.create!(title: Faker::Food.dish,
                                        description: Faker::GreekPhilosophers.quote,
                                        depositor_id: project_owners.sample&.id,
                                        project_id: project.id,
                                        is_public: visibility
        )
        if !collection.nil?
          new_collections += 1
        end

        if include_image
          record_image(collection)
        end
      end

      if num_collections != new_collections
        warn "WARNING: Expected #{num_collections} new collections for project #{project.id}, got #{new_collections}"
      else
        puts "Created #{new_collections} collections in project #{project.id}"
      end
    end
  end

  def create_core_files
    Collection.all.each do |collection|
      project = collection.project
      collection_users = project.members.values.flatten.shuffle
      visibility = collection.is_public
      ography_types = CoreFile.all_ography_types

      # Create 3 regular TEI content files
      3.times do |i|
        core_file = CoreFile.create!(title: "#{Faker::Book.title} #{i + 1}",
                                 description: Faker::Book.genre,
                                 depositor_id: collection_users.sample&.id,
                                 collections: [ collection ].compact,
                                 is_public: [ visibility, !visibility ].sample,
                                 tei_authors: Faker::Creature.name
        )

        # Attach TEI file (required for non-ography files)
        attach_tei_file(core_file)

        if core_file.save
          puts "Core file #{core_file.id} created within Collection #{collection.id}"
        else
          puts "Create Core Files task failed: #{core_file.errors.full_messages.join(', ')}"
        end
      end

      # Create 3 ography support files (don't need TEI)
      2.times do
        core_file = CoreFile.create!(title: Faker::Book.title,
                                    description: Faker::Book.genre,
                                    depositor_id: collection_users.sample&.id,
                                    collections: [ collection ].compact,
                                    is_public: visibility,
                                    ography_type: ography_types.sample,
                                    tei_authors: Faker::Artist.name
        )

        if core_file.persisted?
          puts "Ography file #{core_file.id} (#{core_file.ography_type}) created within Collection #{collection.id}"
          sleep 0.3  # Longer delay
        else
          puts "Create Ography Files task failed: #{core_file.errors.full_messages.join(', ')}"
        end
      end

      # Clear connection pool after each collection
      ActiveRecord::Base.connection_pool.release_connection
      puts "-> Completed collection #{collection.id}"
    end

    puts "Core file creation complete!"
  end

  def attach_tei_file(core_file)
    # Create a minimal valid TEI XML document
    tei_content = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <TEI xmlns="http://www.tei-c.org/ns/1.0">
        <teiHeader>
          <fileDesc>
            <titleStmt>
              <title>#{core_file.title}</title>
            </titleStmt>
            <publicationStmt>
              <p>Sample TEI document for #{core_file.title}</p>
            </publicationStmt>
            <sourceDesc>
              <p>Generated dummy data</p>
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

    # If RAW_TEI_URL is provided, try to fetch real TEI content
    if RAW_TEI_URL.present?
      begin
        tei_data = URI.open(RAW_TEI_URL)
        core_file.tei_file.attach(io: tei_data, filename: "#{core_file.title.parameterize}.xml", content_type: "application/xml")
        return
      rescue => e
        puts "Failed to fetch TEI from URL, using generated content: #{e.message}"
      end
    end

    # Use generated TEI content as fallback
    core_file.tei_file.attach(
      io: StringIO.new(tei_content),
      filename: "#{core_file.title.parameterize}.xml",
      content_type: "application/xml"
    )
  end

  desc "generate all dummy data"
  task run_all: [:environment, :check_queue_adapter] do
    # Start or restart Solr service for connection to instance
    system("solr restart")

    Rake::Task["dummy_data_generator:user_records"].invoke
    Rake::Task["dummy_data_generator:non_user_records"].invoke
  end

  desc "create user table records"
  task user_records: :environment do
    puts "Creating admin user..."
    Rake::Task["dummy_data_generator:admin_user"].invoke

    puts "Creating debug user..."
    Rake::Task["dummy_data_generator:debug_non_admin_user"].invoke

    Rake::Task["dummy_data_generator:non_admin_users"].invoke
  end

  desc "create non-user table records"
  task non_user_records: [:environment, :check_queue_adapter] do
    puts "Creating projects..."
    new_projects = create_projects

    puts "Creating project members..."
    create_project_members(new_projects)

    puts "Creating collections..."
    create_collections(new_projects)

    if [ User, Project, ProjectMember, Collection ].map(&:any?).include?(false)
      puts "Deleting Solr index"
      Rake::Task["dummy_data_generator:delete_indexed"].invoke

      puts "Recreating database"
      Rake::Task["db:drop"].invoke
      Rake::Task["db:create"].invoke
      Rake::Task["db:migrate"].invoke
      Rake::Task["dummy_data_generator:all_users"].invoke
    else
      puts "Creating core files"
      Rake::Task["dummy_data_generator:core_files"].invoke
    end
  end

  desc "creates projects"
  task projects: :environment do
    create_projects
  end

  desc "creates project members"
  task project_members: :environment do
    if Project.any?
      create_project_members
    else
      warn "There are no projects for which to create members."
    end
  end

  desc "creates collections"
  task collections: :environment do
    if Project.any?
      create_collections
    else
      warn "There are no projects for which to create collections."
    end
  end

  desc "creates core files"
  task core_files: [:environment, :check_queue_adapter] do

    if Collection.any?
      create_core_files
    else
      warn 'There are no collections for which to create core files.'
    end
  end

  desc "creates admin user"
  task admin_user: :environment do
    email = ENV.fetch("DUMMY_ADMIN_EMAIL")
    password = ENV.fetch("DUMMY_ADMIN_PASSWORD")

    user = User.create!(name: "Admin",
                        email: email,
                        bio: Faker::Lorem.paragraph,
                        password: password,
                        admin_at: Time.current
    )

    puts "Admin user #{user.id} has been created." unless user.nil?
  end

  desc "creates debug non-admin user"
  task debug_non_admin_user: :environment do
    email = ENV.fetch("DUMMY_DEBUG_EMAIL")
    password = ENV.fetch("DUMMY_DEBUG_PASSWORD")

    user = User.create!(name: "Debug",
                        email: email,
                        bio: Faker::Lorem.paragraph,
                        password: password
    )

    puts "Debug non-admin user #{user.id} has been created." unless user.nil?
  end

  desc "creates non-admin users"
  task non_admin_users: :environment do
    # Create 275 new non-admin users if "num_non_admin_users" was not set.
    num_non_admin_users = ENV['num_non_admin_users'].nil? ? 275 : Integer(ENV['num_non_admin_users'])
    puts "Creating #{num_non_admin_users} non-admin users..."
    
    new_users = 0
    num_non_admin_users.times do
      user = User.create!(name: Faker::Name.unique.name,
                          email: Faker::Internet.email,
                          bio: Faker::Lorem.paragraph,
                          password: Faker::Internet.password
      )

      if !user.nil?
        new_users += 1
      end
    end
    
    if new_users != num_non_admin_users
      warn "WARNING: Expected #{num_non_admin_users} new users, got #{new_users}."
    else
      puts "Created #{new_users} non-admin users."
    end
  end

  desc "deletes records from solr index"
  task delete_indexed: :environment do
    SolrHelpers.delete_all_indexed_records
  end
end
