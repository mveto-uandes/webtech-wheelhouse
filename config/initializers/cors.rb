# The personal page reads the price list from another origin: GitHub Pages once
# published, and a local server on port 8000 while it's being worked on. Only
# those two origins, only the public price list, only GET. Repairs and creating
# a service need the token, so no page is allowed to call them.
#
# A request without an Origin header (curl, the accounting program) isn't
# affected: CORS is a rule browsers follow.
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "https://mveto-uandes.github.io", "http://localhost:8000"

    resource "/api/v1/services", headers: :any, methods: [ :get ]
    resource "/api/v1/services/*", headers: :any, methods: [ :get ]
  end
end
