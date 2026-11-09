# Action Cable is not loaded (config/application.rb leaves out its engine), but
# solid_cable defines part of the ActionCable module for its adapter. turbo-rails
# only skips eager loading its app/channels when ActionCable is not defined at all,
# so in production (eager_load = true) it loaded Turbo::StreamsChannel, whose
# parent class ActionCable::Channel::Base doesn't exist, and the app failed to boot.
# Same rule as turbo-rails, checked against the engine: no Action Cable engine, no
# Turbo channel. Nothing in the app broadcasts over Turbo Streams.
unless defined?(ActionCable::Engine)
  Rails.autoloaders.once.do_not_eager_load(Turbo::Engine.root.join("app/channels").to_s)
end
