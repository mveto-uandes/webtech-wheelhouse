# Deployment

Wheelhouse runs in production at **<http://PRODUCTION_IP>**, over plain HTTP (no domain name; what
that gives up is in [`decisions.md`](decisions.md), "Lab 13"). It's deployed with Kamal 2 from
[`config/deploy.yml`](../config/deploy.yml). How to deploy it to a droplet of your own is in the
[README](../README.md#deploying).

## The droplet

| | |
| --- | --- |
| Provider | DigitalOcean |
| Region | PRODUCTION_REGION |
| Size | PRODUCTION_SIZE |
| Image | Ubuntu PRODUCTION_UBUNTU x64 |
| SSH | key only (`PasswordAuthentication no`; a password login is refused) |

The image is **built on the laptop** (x86_64, `builder: arch: amd64`), which is the droplet's
architecture, so the build needs no emulation and no remote builder. Kamal pushes it to Docker Hub
(`KAMAL_REGISTRY_USERNAME/webtech-wheelhouse`, tagged with the commit's SHA), and the droplet
pulls it from there.

## The containers

Every container on the droplet was started by Kamal:

| Container | What it runs | Port |
| --- | --- | --- |
| `kamal-proxy` | Kamal's reverse proxy. It receives every request and passes it to the current app container; during a deploy it switches to the new one once `/up` answers. | `80` on the droplet (published to the internet) |
| `webtech_wheelhouse-web-<sha>` | The app: Thruster in front of Puma (Rails), with Solid Queue's supervisor inside Puma (`SOLID_QUEUE_IN_PUMA`), so the same container runs the jobs. | `80` inside Kamal's Docker network only |
| `webtech_wheelhouse-db` | PostgreSQL 18, the Kamal accessory. | `5432` inside Kamal's Docker network only; no port published |

PostgreSQL publishes no port (`config/deploy.yml` gives the accessory no `port:`), so it can't be
reached from the internet, nor from the droplet's own network interfaces: only containers on the
`kamal` Docker network reach it, by the name `webtech_wheelhouse-db`. From the laptop,
`nc -vz -w 5 PRODUCTION_IP 5432` fails.

## Where each piece of state lives

| State | Where | In a `kamal deploy` |
| --- | --- | --- |
| **The rows** (four databases: `webtech_wheelhouse_production`, `_queue`, `_cache`, `_cable`) | The `webtech_wheelhouse-db` container, with its data directory on the droplet's disk at `/root/webtech_wheelhouse-db/data` (mounted at `/var/lib/postgresql`) | Untouched: a deploy replaces only the app container. The accessory keeps running; if it restarts, it reopens the same directory. New migrations run when the new container starts (`db:prepare` in `bin/docker-entrypoint`). |
| **The photos** (Active Storage, Disk service) | The Docker volume `webtech_wheelhouse_storage` on the droplet's disk (`/var/lib/docker/volumes/...`), mounted at `/rails/storage` | Untouched: the new container mounts the same volume, so a photo uploaded before the deploy is still there after it. |
| **The jobs** (Solid Queue) | Rows in `webtech_wheelhouse_production_queue`, run by the worker inside the app container | Jobs already queued stay in the database; the new container's worker picks them up. The old container finishes what it's running before it stops. |
| **The emails** | Not stored: a job hands them to Brevo over SMTP (`smtp-relay.brevo.com`, **port 2525**), and Brevo delivers them | Nothing to keep. An email whose job hasn't run yet waits in the queue database. |
| Cache (Solid Cache) | `webtech_wheelhouse_production_cache` | Kept. |
| Logs | The container's stdout (`bin/kamal logs`) | Each container has its own; the old one's go when it's removed. |

## The databases and the seed

`bin/docker-entrypoint` runs `bin/rails db:prepare` every time the app container starts. On the
first start (during `kamal setup`) the databases didn't exist, so `db:prepare` created the four of
them, loaded their schemas (`db/schema.rb`, `db/queue_schema.rb`, `db/cache_schema.rb`,
`db/cable_schema.rb`) and **ran `db/seeds.rb` once**, because it had just created the primary
database. It finished without errors in production: SEED_LOAD_TIME. The seed sends no email (it
only creates rows; the welcome email is sent only by the sign-up page).

On every later start the databases exist, so `db:prepare` only runs pending migrations and never
the seed again.

Right after, every seeded account's password was replaced with a random one, generated on the
server from the console (the command has no password in it, so none reached Kamal's audit log).
The new passwords aren't in the repository, and the seed only sets a password when it creates an
account.

## The jobs and the email

Solid Queue runs inside Puma. How it was checked:

- The password email asked for at `/passwords/new` arrived JOB_CHECK.
- The queue database has nothing waiting or failed:

  ```
  QUEUE_CHECK_OUTPUT
  ```

DigitalOcean blocks outgoing SMTP on ports 25, 465 and 587 on new droplets, so the app talks to
Brevo on **port 2525** (STARTTLS). The sender is an address Brevo has verified. The links in the
emails are built from `APP_HOST`, so they open `http://PRODUCTION_IP/...`.

## The API and CORS

The API answers at `http://PRODUCTION_IP/api/v1`, with the production token. The personal page is
read from **`http://localhost:8000`** (scheme `http`, host `localhost`, port `8000`), served with
`python3 -m http.server 8000` from the page's repository, with its API constant set to the
droplet's IP. That origin is allowed by `config/initializers/cors.rb`:

```
curl -i -H "Origin: http://localhost:8000" http://PRODUCTION_IP/api/v1/services
```

answers with `access-control-allow-origin: http://localhost:8000`.

## Secrets

No value is in the repository or in the image. `.kamal/secrets` holds only the expressions that
read each value on the laptop.

| Secret | Where its value is kept | How it reaches the server |
| --- | --- | --- |
| `KAMAL_REGISTRY_PASSWORD` | A Docker Hub personal access token (Read & Write), exported on the laptop | Used by Kamal to `docker login` on the laptop and on the droplet. Not given to any container. |
| `WHEELHOUSE_DB_PASSWORD` | Exported on the laptop (generated with `openssl rand`) | `.kamal/secrets` passes it as `POSTGRES_PASSWORD` to the accessory (which creates the role with it) and as `WEBTECH_WHEELHOUSE_DATABASE_PASSWORD` to the app. Kamal writes both to env files under `.kamal/` on the droplet (mode 600), not into the image. |
| `RAILS_MASTER_KEY` | `config/credentials/production.key` on the laptop (ignored by git and by `.dockerignore`) | `.kamal/secrets` reads the file; the app gets it as an environment variable and decrypts `config/credentials/production.yml.enc` with it. |
| `secret_key_base` | Inside the production credentials | Through `RAILS_MASTER_KEY`. |
| `api_token` (the API's Bearer token) | Inside the production credentials | Through `RAILS_MASTER_KEY`. |
| `smtp.password` (Brevo SMTP key) and `smtp.user_name` | Inside the production credentials | Through `RAILS_MASTER_KEY`. No environment variable of its own. |
| Production account passwords | Only with the owner of the deployment | Set from the console; stored as bcrypt digests. |

## Deploys

| # | Command | Commit | When |
| --- | --- | --- | --- |
| 1 | `bin/kamal setup` | DEPLOY_1_SHA | DEPLOY_1_TIME |
| 2 | `bin/kamal deploy` | DEPLOY_2_SHA | DEPLOY_2_TIME |
| 3 | `bin/kamal rollback DEPLOY_1_SHA` | (back to DEPLOY_1_SHA) | ROLLBACK_TIME |
| 4 | `bin/kamal deploy` | DEPLOY_2_SHA | DEPLOY_4_TIME |

### The rollback

ROLLBACK_TEXT

## Evidence

Taken after the last deploy.

### `bin/kamal app details`

```
APP_DETAILS_OUTPUT
```

### `bin/kamal accessory details db`

```
ACCESSORY_DETAILS_OUTPUT
```

### `bin/kamal audit`

```
AUDIT_OUTPUT
```
