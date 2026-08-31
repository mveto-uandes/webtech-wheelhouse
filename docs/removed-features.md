# Removed features (Lab 4)

`rails new` with Rails 8 defaults loads more than the four public pages need, and some of it
adds routes that aren't part of this lab's declared routes (`bin/rails routes` must show
exactly the four pages + `/up`). These were removed to keep the route list clean:

## What was removed

- **Turbo (`turbo-rails` gem)** — removed from `Gemfile`, its pin from `config/importmap.rb`,
  and its `import` from `app/javascript/application.js`.
- **ActiveStorage, ActionMailbox, ActionCable** — no longer loaded. `config/application.rb`
  used to `require "rails/all"`; it now requires only the specific railties this app uses
  (`active_model`, `active_job`, `active_record`, `action_controller`, `action_mailer`,
  `action_view`, `rails/test_unit`).
- `config.active_storage.service = ...` lines commented out in
  `config/environments/{development,test,production}.rb` since ActiveStorage isn't loaded.

## How to bring them back

1. In `config/application.rb`, replace the explicit railtie requires with `require "rails/all"`.
2. Add `gem "turbo-rails"` back to the `Gemfile` and run `bundle install`.
3. Uncomment the `config.active_storage.service` lines.
4. Re-add `pin "@hotwired/turbo-rails", to: "turbo.min.js"` to `config/importmap.rb` and
   `import "@hotwired/turbo-rails"` to `app/javascript/application.js`.
5. Run `bin/rails routes` to confirm the extra routes are back.

This will matter starting Lab 5, when models/tables are introduced and ActiveStorage or Turbo
may become useful again.
