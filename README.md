# Wheelhouse

Wheelhouse is the site of a bike repair shop. Its public pages show what the shop does, its price
list, how to visit and who runs it. Its records pages (under **Records** in the navbar) let the
counter keep track of customers, bikes, staff, services and repairs. A repair carries the photos
taken when the bike came in and the mechanic's diagnosis, written as formatted text.

See `docs/` for the specification this app was built from:

- [User stories](docs/user-stories.md)
- [Domain model](docs/domain-model.md)
- [Wireframes](docs/wireframe.md)
- [Design decisions](docs/decisions.md)
- [The JSON API](docs/api.md)

The shop's price list is also shown on my personal page, which reads it from this app's API:
[mveto-uandes.github.io/webtech-lab-01](https://mveto-uandes.github.io/webtech-lab-01/#prices).

## Prerequisites

- **Ruby 4.0.6** and **Rails 8.1.3.1** (Rails is installed by `bundle install`).
- **Node 26** and **npm**, to build the stylesheet.
- **PostgreSQL 18**, running locally, with a role that can create databases (the app connects as
  your own user, with no password).
- **libvips 8.x**, which makes the thumbnails of the repair photos. Without it the photos upload
  but every thumbnail fails to load. Install it with your system's package manager:

  | System | Command |
  | --- | --- |
  | Ubuntu 24.04 / Linux Mint 22 / Debian 13 | `sudo apt install libvips42t64` |
  | Older Ubuntu or Debian | `sudo apt install libvips42` |
  | Fedora | `sudo dnf install vips` |
  | macOS (Homebrew) | `brew install vips` |

  Check it with `vips --version` (on Debian and Ubuntu, `sudo apt install libvips-tools` adds that
  command). Other systems: see [libvips' install page](https://www.libvips.org/install.html).

## Setup

From a fresh clone:

```
git clone https://github.com/mveto-uandes/webtech-wheelhouse.git
cd webtech-wheelhouse
bundle install
npm install
npm run build:css
bin/rails db:create db:migrate db:seed
```

The seed loads services (priced in Chilean pesos), staff, customers, bikes and 17 repairs. 13 of them have intake photos and a
diagnosis. The photos come from `db/seeds/` (their authors and licenses are in
[`db/seeds/CREDITS.md`](db/seeds/CREDITS.md)). It's safe to run `bin/rails db:seed` again: it adds
nothing that's already there.

To start over from an empty database: `bin/rails db:drop db:create db:migrate db:seed`.

## Running the app

```
bin/dev
```

Then visit `http://localhost:3000`. The repairs list is at
`http://localhost:3000/catalog/repairs`, and each repair with photos shows a thumbnail. The first
time a thumbnail is shown, libvips makes it, so the first page load is a little slower.

## The JSON API

The app answers JSON under `/api/v1`. Reading the price list is public. Reading repairs and adding a
service need a token. Every route, document and error is described in [`docs/api.md`](docs/api.md).

### Setting the token

The token lives in the app's encrypted credentials, under the key `api_token`. The repository's
`config/credentials.yml.enc` is encrypted with a key that isn't in the repository, so on a fresh
clone you make your own development credentials:

1. Make up a token. `bin/rails secret` prints a long random one; copy it.
2. Open the development credentials (this creates them, and a key for them that git ignores):

   ```
   EDITOR=nano bin/rails credentials:edit --environment development
   ```

   Use whichever editor you like (`EDITOR="code --wait"` for VS Code).
3. Add one line with your token, then save and close the editor:

   ```
   api_token: paste-your-token-here
   ```

4. Check it: `bin/rails runner 'puts Rails.application.credentials.api_token'` prints your token.

Don't commit `config/credentials/development.yml.enc` or `config/credentials/development.key`.
Restart `bin/dev` after changing the token. Without a token set, every route that needs one answers
`401`.

### Asking the API from the terminal

With the app running on port 3000:

```
# The price list (public)
curl http://localhost:3000/api/v1/services

# One service
curl http://localhost:3000/api/v1/services/1

# The repairs, with the token
TOKEN=paste-your-token-here
curl -H "Authorization: Bearer $TOKEN" http://localhost:3000/api/v1/repairs

# Only the repairs waiting on the customer's answer
curl -H "Authorization: Bearer $TOKEN" "http://localhost:3000/api/v1/repairs?state=quoted"

# Add a service to the price list
curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"service": {"name": "Disc brake bleed", "price": "22000"}}' \
  http://localhost:3000/api/v1/services
```

Add `-i` to any of them to see the status and the headers.

### The price list on the personal page

The [personal page](https://mveto-uandes.github.io/webtech-lab-01/#prices) asks the API at
`http://localhost:3000/api/v1`, so **the app has to run on port 3000** (the port `bin/dev` uses) on
the computer where you open the page. Start the app with `bin/dev`, then open the page: the "Bike
repair prices" section shows the price list. With the app stopped, the section says the API isn't
answering.

Browsers only let two origins read the API: the published page (`https://mveto-uandes.github.io`)
and `http://localhost:8000`, where the page is served while it's being worked on
(`python3 -m http.server 8000` from the page's repository). Any other page gets a CORS error. In
Chrome, the published page may first ask for permission to reach devices on your local network:
allow it.

## Where uploaded files go

In development, uploaded photos are stored on disk in `storage/`, at the root of the project. That
folder is ignored by git: no uploaded file is ever committed. Deleting the database doesn't delete
those files, so after a `db:drop` you can also empty `storage/` (keep `storage/.keep`).
