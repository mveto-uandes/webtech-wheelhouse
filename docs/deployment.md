# Deployment

Wheelhouse runs in production at **<http://137.184.104.39>**, over plain HTTP (no domain name; what
that gives up is in [`decisions.md`](decisions.md), "Lab 13"). It's deployed with Kamal 2 from
[`config/deploy.yml`](../config/deploy.yml). How to deploy it to a droplet of your own is in the
[README](../README.md#deploying).

## The droplet

| | |
| --- | --- |
| Provider | DigitalOcean |
| Region | New York 1 (`nyc1`) |
| Size | Basic, Regular: 2 GB of memory, 1 vCPU, 50 GB disk (created as 512 MB and resized before the first deploy) |
| Image | Ubuntu 24.04.5 LTS x64 |
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
`nc -vz -w 5 137.184.104.39 5432` fails.

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
database. It finished without errors in production: the app container of `kamal setup` printed "Seeded 26 services, 5 employees, 6 accounts, 11 customers, 12 bikes, 17 repairs, 19 repair line items, 23 intake photos, 13 diagnoses." at 2026-11-09 16:44:12 UTC. The seed sends no email (it
only creates rows; the welcome email is sent only by the sign-up page).

On every later start the databases exist, so `db:prepare` only runs pending migrations and never
the seed again.

Right after, every seeded account's password was replaced with a random one, generated on the
server from the console (the command has no password in it, so none reached Kamal's audit log).
The new passwords aren't in the repository, and the seed only sets a password when it creates an
account.

## The jobs and the email

Solid Queue runs inside Puma. How it was checked:

- The password email asked for at `/passwords/new` arrived in the inbox at once: its job was enqueued at 16:54:09 UTC and finished at 16:54:11 (1.7 s; the welcome email took the same). The link in it opened `http://137.184.104.39/passwords/.../edit`, and the new password signed in.
- The queue database has nothing waiting or failed:

  ```
  $ bin/kamal app exec 'bin/rails runner "..."'   # counts of SolidQueue::Job and each execution table
  jobs=27 finished=27 ready=0 scheduled=0 claimed=0 failed=0 blocked=0
  ```

DigitalOcean blocks outgoing SMTP on ports 25, 465 and 587 on new droplets, so the app talks to
Brevo on **port 2525** (STARTTLS). The sender is an address Brevo has verified. The links in the
emails are built from `APP_HOST`, so they open `http://137.184.104.39/...`.

## The API and CORS

The API answers at `http://137.184.104.39/api/v1`, with the production token. The personal page is
read from **`http://localhost:8000`** (scheme `http`, host `localhost`, port `8000`), served with
`python3 -m http.server 8000` from the page's repository, with its API constant set to the
droplet's IP. That origin is allowed by `config/initializers/cors.rb`:

```
curl -i -H "Origin: http://localhost:8000" http://137.184.104.39/api/v1/services
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
| 1 | `bin/kamal setup` | `ba482e6` (ba482e66537b315c7b1c1e417e3e26e73db8afe7) | 2026-11-09 16:28–16:44 UTC (image built and pushed, PostgreSQL booted, app booted, databases created, seed loaded) |
| 2 | `bin/kamal deploy` | `3c0c42c` (3c0c42c141b170f3e3f92cdc7c67b42490a9a88d) | 2026-11-09 16:45–16:48 UTC (adds the SMTP settings to the production credentials) |
| 3 | `bin/kamal rollback ba482e66537b315c7b1c1e417e3e26e73db8afe7` | back to `ba482e6` | 2026-11-09 16:56 UTC |
| 4 | `bin/kamal deploy` | `3c0c42c` (3c0c42c141b170f3e3f92cdc7c67b42490a9a88d) | 2026-11-09 16:57–16:58 UTC (the version in production now) |

### The rollback

After deploy 2, `3c0c42c` was running. It was replaced by the previous version with

```
bin/kamal rollback ba482e66537b315c7b1c1e417e3e26e73db8afe7
```

Kamal started the container of `ba482e6` again (its image was still on the droplet), moved kamal-proxy to it once `/up` answered, and stopped the container of `3c0c42c`. The app answered with the old version: `docker ps` on the droplet showed `webtech_wheelhouse-web-ba482e66537b315c7b1c1e417e3e26e73db8afe7` with image `matukingg/webtech-wheelhouse:ba482e66537b315c7b1c1e417e3e26e73db8afe7`, `printenv KAMAL_VERSION` inside it printed `ba482e66537b315c7b1c1e417e3e26e73db8afe7`, and `/up` answered `200`. The rows and the photos were the same (they live outside the container). For that minute email didn't work: `ba482e6`'s credentials still had placeholder SMTP settings, which is what `3c0c42c` fixed. Then `bin/kamal deploy` put `3c0c42c` back (deploy 4).

| | Version | Commit |
| --- | --- | --- |
| Replaced | `3c0c42c141b170f3e3f92cdc7c67b42490a9a88d` | `3c0c42c` lab 13: smtp credentials |
| Came back | `ba482e66537b315c7b1c1e417e3e26e73db8afe7` | `ba482e6` lab 13 |

## Checks after the deploys

**Plain HTTP, no redirect to `https://`:**

```
$ curl -I http://137.184.104.39/
HTTP/1.1 302 Found
Location: http://137.184.104.39/session/new
Set-Cookie: _webtech_wheelhouse_session=…; path=/; httponly; samesite=lax
$ curl -I http://137.184.104.39/session/new
HTTP/1.1 200 OK
Set-Cookie: _webtech_wheelhouse_session=…; path=/; httponly; samesite=lax
$ curl -I http://137.184.104.39/up
HTTP/1.1 200 OK
```

No `Strict-Transport-Security`, no `Location` to `https://`, and the session cookie has no `Secure`.

**The rows and the photos survive.** Repair #18 was taken in from the browser, with an intake
photo, while `3c0c42c` was running (before the rollback and deploy 4). Afterwards it was checked
from the console (`Repair.find(18)`, its photo count) and the photo was downloaded from its page's
URL (`200 image/jpeg`):

| After | Repair #18 | Its photo |
| --- | --- | --- |
| the rollback (16:56) and `kamal deploy` (16:58) | there | `200 image/jpeg` |
| `bin/kamal accessory reboot db` (16:58) | there (18 repairs, 7 accounts) | `200 image/jpeg` |
| a reboot of the droplet (`systemctl reboot`, 16:59; `/up` answered again 42 s later, every container restarted by Docker) | there (18 repairs, 7 accounts) | `200 image/jpeg` |

**PostgreSQL can't be reached from the internet:**

```
$ nc -vz -w 5 137.184.104.39 5432
nc: connect to 137.184.104.39 port 5432 (tcp) failed: Connection refused
```

**SSH takes only a key:**

```
$ ssh -o PubkeyAuthentication=no -o PreferredAuthentications=password root@137.184.104.39
root@137.184.104.39: Permission denied (publickey).
```

(`sshd -T` on the droplet: `passwordauthentication no`, `kbdinteractiveauthentication no`.)

**The API** answers every route of `/api/v1` with the same statuses as locally: services index/show
`200` (`404` for a missing id), repairs without a token or with a wrong one `401`, with the
production token `200` (also `?state=quoted`), `?state=bogus` `400`, a missing repair `404`, an
invalid service `422`, a malformed JSON body `400`, `/api/v1` and unknown paths `404`.

**The personal page** served from `http://localhost:8000` with its API constant set to
`http://137.184.104.39/api/v1` showed the price list and the service asked by id (the change wasn't
committed in `webtech-lab-01`).

## Evidence

Taken after the last deploy.

### `bin/kamal app details`

```
$ bin/kamal app details
  INFO [1c5eb5c9] Running docker ps --filter label=service=webtech_wheelhouse --filter label=destination= --filter label=role=web on 137.184.104.39
  INFO [1c5eb5c9] Finished in 3.786 seconds with exit status 0 (successful).
App Host: 137.184.104.39
CONTAINER ID   IMAGE                                                                   COMMAND                  CREATED         STATUS         PORTS     NAMES
b4173177d089   matukingg/webtech-wheelhouse:3c0c42c141b170f3e3f92cdc7c67b42490a9a88d   "/rails/bin/docker-e…"   4 minutes ago   Up 3 minutes   80/tcp    webtech_wheelhouse-web-3c0c42c141b170f3e3f92cdc7c67b42490a9a88d
```

### `bin/kamal accessory details db`

```
$ bin/kamal accessory details db
  INFO [a8520841] Running docker ps --filter label=service=webtech_wheelhouse-db on 137.184.104.39
  INFO [a8520841] Finished in 2.899 seconds with exit status 0 (successful).
Accessory db Host: 137.184.104.39
CONTAINER ID   IMAGE         COMMAND                  CREATED         STATUS         PORTS      NAMES
1dc3fee1cf79   postgres:18   "docker-entrypoint.s…"   4 minutes ago   Up 3 minutes   5432/tcp   webtech_wheelhouse-db
```

### `bin/kamal audit`

```
$ bin/kamal audit
  INFO [0cf053a1] Running /usr/bin/env tail -n 50 .kamal/webtech_wheelhouse-audit.log on 137.184.104.39
  INFO [0cf053a1] Finished in 2.508 seconds with exit status 0 (successful).
App Host: 137.184.104.39
[2026-11-09T16:42:54Z] [matias.veto@gmail.com] Pulled image with version ba482e66537b315c7b1c1e417e3e26e73db8afe7
[2026-11-09T16:43:30Z] [matias.veto@gmail.com] Booted db accessory
[2026-11-09T16:43:54Z] [matias.veto@gmail.com] [web] Booted app version ba482e66537b315c7b1c1e417e3e26e73db8afe7
[2026-11-09T16:44:18Z] [matias.veto@gmail.com] Tagging matukingg/webtech-wheelhouse:ba482e66537b315c7b1c1e417e3e26e73db8afe7 as the latest image
[2026-11-09T16:44:19Z] [matias.veto@gmail.com] Pruned containers
[2026-11-09T16:44:21Z] [matias.veto@gmail.com] Pruned images
[2026-11-09T16:45:01Z] [matias.veto@gmail.com] Executed cmd 'bin/rails runner "User.includes(:employee).order(:id).each { |u| pw = SecureRandom.alphanumeric(16); u.update!(password: pw); Session.where(user: u).delete_all; puts [u.email_address, u.role, u.employee&.name || %q(-), pw].join(%q( | )) }"' on app version latest
[2026-11-09T16:47:34Z] [matias.veto@gmail.com] Pulled image with version 3c0c42c141b170f3e3f92cdc7c67b42490a9a88d
[2026-11-09T16:47:52Z] [matias.veto@gmail.com] [web] Booted app version 3c0c42c141b170f3e3f92cdc7c67b42490a9a88d
[2026-11-09T16:48:07Z] [matias.veto@gmail.com] Tagging matukingg/webtech-wheelhouse:3c0c42c141b170f3e3f92cdc7c67b42490a9a88d as the latest image
[2026-11-09T16:48:08Z] [matias.veto@gmail.com] Pruned containers
[2026-11-09T16:48:10Z] [matias.veto@gmail.com] Pruned images
[2026-11-09T16:48:25Z] [matias.veto@gmail.com] Executed cmd 'bin/rails runner "s = ActionMailer::Base.smtp_settings; smtp = Net::SMTP.new(s[:address], s[:port]); smtp.enable_starttls_auto; smtp.open_timeout = 10; smtp.start(%q(localhost), s[:user_name], s[:password], :plain) { puts %Q(SMTP AUTH OK \#{s[:address]}:\#{s[:port]}) }; puts %Q(from domain: \#{ApplicationMailer.default_params[:from].call.split(%q(@)).last}); puts ActionMailer::Base.default_url_options"' on app version latest
[2026-11-09T16:56:03Z] [matias.veto@gmail.com] Executed cmd 'bin/rails runner "q = SolidQueue; puts %Q(jobs=\#{q::Job.count} finished=\#{q::Job.finished.count} ready=\#{q::ReadyExecution.count} scheduled=\#{q::ScheduledExecution.count} claimed=\#{q::ClaimedExecution.count} failed=\#{q::FailedExecution.count} blocked=\#{q::BlockedExecution.count}); q::Job.where(class_name: %q(ActionMailer::MailDeliveryJob)).order(:id).each { |j| puts %Q(mail job \#{j.id} \#{j.arguments[%q(arguments)].first(2).join(%q(#))} enqueued=\#{j.created_at.utc.iso8601} finished=\#{j.finished_at&.utc&.iso8601} secs=\#{(j.finished_at - j.created_at).round(1) rescue nil}) }; puts %Q(users=\#{User.count})"' on app version latest
[2026-11-09T16:56:32Z] [matias.veto@gmail.com] [web] Renaming container ba482e66537b315c7b1c1e417e3e26e73db8afe7 to ba482e66537b315c7b1c1e417e3e26e73db8afe7_replaced_7106a75e98f0cbe6
[2026-11-09T16:56:34Z] [matias.veto@gmail.com] [web] Booted app version ba482e66537b315c7b1c1e417e3e26e73db8afe7
[2026-11-09T16:56:47Z] [matias.veto@gmail.com] Tagging matukingg/webtech-wheelhouse:ba482e66537b315c7b1c1e417e3e26e73db8afe7 as the latest image
[2026-11-09T16:56:55Z] [matias.veto@gmail.com] Executed cmd 'printenv KAMAL_VERSION' on app version latest
[2026-11-09T16:57:44Z] [matias.veto@gmail.com] Pulled image with version 3c0c42c141b170f3e3f92cdc7c67b42490a9a88d
[2026-11-09T16:57:55Z] [matias.veto@gmail.com] [web] Renaming container 3c0c42c141b170f3e3f92cdc7c67b42490a9a88d to 3c0c42c141b170f3e3f92cdc7c67b42490a9a88d_replaced_322869f221dbbf6f
[2026-11-09T16:57:57Z] [matias.veto@gmail.com] [web] Booted app version 3c0c42c141b170f3e3f92cdc7c67b42490a9a88d
[2026-11-09T16:58:11Z] [matias.veto@gmail.com] Tagging matukingg/webtech-wheelhouse:3c0c42c141b170f3e3f92cdc7c67b42490a9a88d as the latest image
[2026-11-09T16:58:12Z] [matias.veto@gmail.com] Pruned containers
[2026-11-09T16:58:13Z] [matias.veto@gmail.com] Pruned images
[2026-11-09T16:58:34Z] [matias.veto@gmail.com] Pull db accessory image
[2026-11-09T16:58:36Z] [matias.veto@gmail.com] Stopped db accessory
[2026-11-09T16:58:37Z] [matias.veto@gmail.com] Remove db accessory container
[2026-11-09T16:58:40Z] [matias.veto@gmail.com] Booted db accessory
[2026-11-09T16:58:56Z] [matias.veto@gmail.com] Executed cmd 'bin/rails runner "r = Repair.find(18); puts %Q(repair 18: \#{r.reported_problem} photos=\#{r.intake_photos.count} repairs=\#{Repair.count} users=\#{User.count})"' on app version latest
[2026-11-09T17:00:06Z] [matias.veto@gmail.com] Executed cmd 'bin/rails runner "r = Repair.find(18); puts %Q(repair 18: \#{r.reported_problem} photos=\#{r.intake_photos.count} repairs=\#{Repair.count} users=\#{User.count})"' on app version latest
```
