# Wheelhouse

**In production: <http://PRODUCTION_IP>** (plain HTTP, no domain name; see
[Deploying](#deploying) and [`docs/deployment.md`](docs/deployment.md)).

Wheelhouse is the site of a bike repair shop. The people of the workshop sign in with an email
address and a password; anyone else sees only the price list. Signed in, the shop's pages show what
it does, how to visit and who runs it, and its records pages (under **Records** in the navbar) keep
track of customers, bikes, staff, services and repairs. A repair carries the photos
taken when the bike came in and the mechanic's diagnosis, written as formatted text.

See `docs/` for the specification this app was built from:

- [User stories](docs/user-stories.md)
- [Domain model](docs/domain-model.md)
- [Wireframes](docs/wireframe.md)
- [Design decisions](docs/decisions.md)
- [The JSON API](docs/api.md)
- [Who may do what](docs/permissions.md)
- [How it is deployed](docs/deployment.md)

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

The seed loads services (priced in Chilean pesos), staff, their accounts (see
[Signing in](#signing-in)), customers, bikes and 17 repairs. 13 of them have intake photos and a
diagnosis. The photos come from `db/seeds/` (their authors and licenses are in
[`db/seeds/CREDITS.md`](db/seeds/CREDITS.md)). It's safe to run `bin/rails db:seed` again: it adds
nothing that's already there.

To start over from an empty database: `bin/rails db:drop db:create db:migrate db:seed`.

## Running the app

```
bin/dev
```

Then visit `http://localhost:3000`. It asks you to sign in: use one of the accounts below. The
repairs list is at
`http://localhost:3000/catalog/repairs`, and each repair with photos shows a thumbnail. The first
time a thumbnail is shown, libvips makes it, so the first page load is a little slower.

## Signing in

Every page asks for a session except the price list (`/services`, and the service pages under
**Records → Service Catalog**), the sign-in page, the sign-up page and the pages of a forgotten
password. A page you ask for before signing in opens right after you sign in.

The seed creates these accounts. **They exist only in development**, in the database the seed
fills on your computer; don't use these passwords anywhere else. **They don't sign in to
production**: the same accounts exist there, but every password was changed after the seed was
loaded, and the new ones aren't in this repository.

| Email address | Password | Role | Staff member | What it can do |
| --- | --- | --- | --- | --- |
| `matias@wheelhouse.cl` | `matias-owner-2026` | owner | Matías Veto | Everything: the price list, the staff, customers, bikes, every repair, deleting. |
| `camila@wheelhouse.cl` | `camila-counter-2026` | counter | Camila Soto | Customers and bikes (no deleting), takes repairs in, edits every repair until it's handed back, reads payments. |
| `marco@wheelhouse.cl` | `marco-mechanic-2026` | mechanic | Marco Ibáñez | Reads their own repairs and changes their state, diagnosis and photos until they're handed back. |
| `valentina@wheelhouse.cl` | `valentina-mechanic-2026` | mechanic | Valentina Rojas | The same, on their own repairs. |
| `diego@wheelhouse.cl` | `diego-mechanic-2026` | mechanic | Diego Fuentes | The same, on their own repairs. |
| `trainee@wheelhouse.cl` | `trainee-wheelhouse-2026` | mechanic (the default) | none | A mechanic with no repairs of their own: reads the price list and the staff, and no repairs. |

Every rule, action by action, is in [`docs/permissions.md`](docs/permissions.md). A page or
button an account isn't allowed to use doesn't appear, and asking for it anyway answers a page
that says so (status `403`).

Running the seed again doesn't change these passwords, but a password changed through the
"Forgot your password?" page stays changed until you reset the database.

Anyone can also make an account at **Sign up** (linked from the sign-in page). A new account gets
the default role, `mechanic`, and belongs to nobody on the staff. Roles and staff members are
changed from the console, for example:

```
bin/rails runner 'User.find_by!(email_address: "new@example.com").update!(role: :counter, employee: Employee.find_by!(name: "Camila Soto"))'
```

## Reading the emails

In development the app never sends an email out: there's no mail server and nothing to configure.
Each email is **written to a file in `tmp/mails/`**, named after the address it goes to (for
example `tmp/mails/camila@wheelhouse.cl`). A file holds every email sent to that address, one
after the other, newest last. The text part is plain text, so the links can be copied from it.

The app sends two emails, from a background job right after the page answers:

- **Welcome**, to a new account made at Sign up.
- **Choose a new password**, from "Forgot your password?". Copy the link from the file into the
  browser (the app must be running on port 3000), choose a new password, and sign in with it. The
  link works once and for 15 minutes.

To see both emails without sending them: `http://localhost:3000/rails/mailers`.

To start with no emails, delete `tmp/mails/`.

## The JSON API

The app answers JSON under `/api/v1`. The API doesn't use the accounts or the session: it answers
the same signed in or not. Reading the price list is public. Reading repairs and adding a
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

## Deploying

The production app runs on a DigitalOcean droplet, deployed with [Kamal 2](https://kamal-deploy.org)
from `config/deploy.yml`. How it's laid out (containers, where the data lives, the deploys and the
rollback, every secret) is in [`docs/deployment.md`](docs/deployment.md). To deploy this repository
to a droplet of your own:

**Accounts you need**

- **DigitalOcean**: an Ubuntu droplet with at least 2 GB of memory, created with your SSH key (so
  `ssh root@<IP>` works without a password).
- **Docker Hub**: an account and a personal access token with Read & Write access (Account
  settings → Personal access tokens). Kamal pushes the image there and the droplet pulls it.
- **An SMTP provider** with a free plan that accepts mail on a port DigitalOcean doesn't block
  (it blocks 25, 465 and 587). This app uses Brevo on port 2525, with a verified sender address.

**On your laptop**

- Docker (the image is built there; Kamal is in the Gemfile, so `bundle install` brings it).
- Your own production credentials, because `config/credentials/production.yml.enc` is encrypted
  with a key that isn't in the repository. Delete that file and create yours (this also makes
  `config/credentials/production.key`, which git ignores):

  ```
  rm config/credentials/production.yml.enc
  EDITOR=nano bin/rails credentials:edit --environment production
  ```

  with this content (`bin/rails secret` prints a value for the first two):

  ```
  secret_key_base: <a long random value>
  api_token: <another random value>
  smtp:
    address: smtp-relay.brevo.com
    port: 2525
    user_name: <the provider's SMTP login>
    password: <the provider's SMTP key>
    from: "Wheelhouse <a sender address the provider has verified>"
  ```

- Commit that file: Kamal builds the image from the last commit, not from your working tree.

**Variables to export** (in the shell you deploy from; `.kamal/secrets` reads them and holds no
values)

```
export WHEELHOUSE_HOST=203.0.113.10                # your droplet's IP
export KAMAL_REGISTRY_USERNAME=your-docker-user    # Docker Hub user
export KAMAL_REGISTRY_PASSWORD=dckr_pat_...        # the access token, not the account password
export WHEELHOUSE_DB_PASSWORD=$(openssl rand -hex 24)   # keep it: every later deploy needs the same one
```

**The first command**

```
bin/kamal setup
```

It installs Docker on the droplet, starts PostgreSQL and the app, and the app's first start creates
the four production databases and loads the seed. Then change every seeded password (the seed's
passwords are in this README) from the production console, so the new passwords don't end up in
a command line (Kamal writes every command it runs to an audit log on the server):

```
bin/kamal console
User.find_by!(email_address: "matias@wheelhouse.cl").update!(password: "a-new-password")
```

Later versions go out with `bin/kamal deploy`, and `bin/kamal rollback <version>` puts a previous
one back.
