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

The seed loads services, staff, customers, bikes and 17 repairs. 13 of them have intake photos and a
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

## Where uploaded files go

In development, uploaded photos are stored on disk in `storage/`, at the root of the project. That
folder is ignored by git: no uploaded file is ever committed. Deleting the database doesn't delete
those files, so after a `db:drop` you can also empty `storage/` (keep `storage/.keep`).
