# Wheelhouse

Wheelhouse is the public site for a bike repair shop: what the shop does, its price list, how to
visit, and who runs it. See `docs/` for the specification this app was built from:

- [User stories](docs/user-stories.md)
- [Domain model](docs/domain-model.md)
- [Wireframes](docs/wireframe.md)
- [Design decisions](docs/decisions.md)

## Prerequisites

- Ruby 4.0.6
- Rails 8.1.3.1
- Node 26.8.1 and npm
- PostgreSQL 18, running locally, with a role that can create databases

## Setup

```
bundle install
npm install
bin/rails db:create
```

## Running the app

```
bin/dev
```

Then visit `http://localhost:3000`.
