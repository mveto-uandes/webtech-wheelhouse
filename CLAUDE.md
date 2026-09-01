# Wheelhouse

Rails 8 app for ICC4103 Lab 4, built on top of the Lab 3 `webtech-wheelhouse` repo (same repo,
same git history — `docs/` is Lab 3's spec).

## Stack
- Ruby 4.0.6 (via mise — `eval "$(~/.local/bin/mise activate bash)"` before any rails/ruby/bundle command)
- Rails 8.1.3.1, PostgreSQL 18 adapter
- Bootstrap via cssbundling-rails, compiled with `npm run build:css` (yarn is not installed on
  this machine — package.json scripts were rewritten to use `npm run` instead of `yarn`)

## Current state
- Routes/controller/views for the 4 required pages (home, services, visiting, about) exist in
  `app/controllers/shop_controller.rb` and `app/views/shop/`.
- Services page content is placeholder ("Service 1"..."Service 12", $8888 each) — real shop
  content (name, address, hours, owner bio, real services/prices) still needs to be filled in.
  See `../lab-04-removed-features.md` for why Turbo/ActiveStorage/ActionMailbox were stripped out of
  `config/application.rb` and the Gemfile (they added routes outside the lab's allowed set).
- Full requirement-by-requirement checklist: `../lab-04-requirements.md` (one level up, outside
  this repo, in `web_technologies/`).

## Constraints (from the lab)
No models, no migrations, no `resources` routes, no Bootstrap CDN, no SQLite, no forms, no auth,
no custom JS. See `../lab-04-requirements.md` section 8 for the full list.
