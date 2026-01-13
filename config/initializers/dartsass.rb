# Configure dartsass-rails to build multiple stylesheets
Rails.application.config.dartsass.builds = {
  "application.scss" => "application.css",
  "admin.scss" => "admin.css"
}

# Suppress deprecation warnings until Bootstrap 6 is released
Rails.application.config.dartsass.build_options << " --silence-deprecation=import"
