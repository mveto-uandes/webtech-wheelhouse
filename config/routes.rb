Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "shop#home"
  get "services" => "shop#services", as: :services
  get "visiting" => "shop#visiting", as: :visiting
  get "about" => "shop#about", as: :about

  # Staff/mechanic workflow mockups (static, non-functional — see wireframe flow diagram).
  # Not linked from the main navbar; reachable only by following the flow from the price list.
  get "mockups/dropoff" => "mockups#dropoff", as: :mockup_dropoff
  get "mockups/repair_board" => "mockups#repair_board", as: :mockup_repair_board
  get "mockups/repair_detail" => "mockups#repair_detail", as: :mockup_repair_detail
  get "mockups/quote_approval" => "mockups#quote_approval", as: :mockup_quote_approval
end
