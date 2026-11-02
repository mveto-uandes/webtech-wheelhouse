**Can a bike have more than one repair open at the same time, or a repair cover more than one bike?**
The description always talks about one bike at a time, so I assumed one repair is always for exactly one bike, and a bike can have many repairs over time but not two open ones at once. If that's wrong, `repairs` would probably need something to stop two open repairs on the same bike, or the relationship would need to change to allow it on purpose.

**Who is actually allowed to approve or decline the quote?**
The owner says "we call the person... wait for them to say yes," which sounds like only the registered customer decides. I assumed that, so there's no field for anyone else authorizing a repair, like someone picking up a bike for a friend. If that's wrong, I'd probably need an `authorized_by` field somewhere, or a way to log who actually said yes if it wasn't the owner of the bike.

**Do photos need to be linked to which employee took them?**
The owner says photos are so nobody argues later about who made a scratch, which made me think accountability could matter, but never says photos are tied to a specific person. I assumed they don't need that, so `photos` only has `bike_id` and `taken_at`, no employee. If that's wrong, `photos` would need an `employee_id` column pointing at whoever took it.

## Lab 7: what happens when something gets deleted

**Which `dependent:` option did each `has_many` get?**
- `Customer#bikes` and `Service#repair_line_items` are `restrict_with_error`, because the lab asks for it: a customer with bikes, or a service that was charged at least once, can't be deleted.
- `Bike#repairs` is also `restrict_with_error`. A bike's repair history is the shop's record of what was done and charged, so I didn't want deleting a bike to quietly wipe it.
- `Repair#payments` is `restrict_with_error` too. Money that was actually received shouldn't disappear because someone deleted the repair.
- `Repair#repair_line_items` is `destroy`. A line item makes no sense without its repair, so if a repair (with no payments) is deleted, its lines go with it.
- `Employee#repairs` is `nullify`. `mechanic_id` can already be null ("unassigned"), so if a mechanic leaves, their repairs stay and just become unassigned.
- The `through` associations (`Customer#repairs`, `Service#repairs`, `Repair#services`) repeat the option of the association they go through, so the two never disagree.

**How is "the customer's answer" recorded?**
There's no separate column for it, only `status`. What the customer says yes to is the quote, and the quote is the repair's line items. So a repair that is `in_repair`, `ready_for_pickup` or `completed` must have at least one line item, which is the approved work. A column like `approved_at` would be more explicit, but the lab doesn't allow new migrations.

**Which columns get cleaned up before saving?**
Bike serial numbers are stripped and upper-cased in a `before_validation` callback, so `" wtu123 "` and `"WTU123"` count as the same bike. Service names and customer names get their extra spaces squeezed out with `normalizes`, so `"Flat  tire repair "` can't sneak past the unique name on the price list. They aren't upper-cased, though, because they're shown to people as typed.

## Lab 8: writing from the browser

**How many empty service rows does the repair form offer, and how do you get more?**
The repair form always shows its current lines plus 3 empty rows. That covers most drop-offs: the usual repair in the seed has one or two services. The form has to work without JavaScript, so it can't grow by itself. If a repair needs more than 3 new services, you save it, press Edit, and you get 3 more empty rows. A row left on "No service" is ignored.

**Why are the line errors named after the service?**
On the repair's form there can be several lines, so "Charged price must be more than 0" doesn't tell you which one. The message says "Charged price for Flat tire repair must be more than 0", and the price field on that row is marked in red.

**Why are payments still read-only?**
The lab asks for full create/edit/delete on customers, bikes, repairs, services and staff. Payments aren't in that list, and the counter doesn't take payments in the app yet, so they keep their Lab 6 pages.

**Why is Turbo back?**
It was removed in Lab 4 to keep the route list short. The Delete button asks for confirmation with `data-turbo-confirm`, which is what Rails provides for that, so `turbo-rails` is back in the Gemfile and the import map.

## Lab 9: intake photos and the diagnosis

**Which photos are accepted?**
JPEG, PNG and WebP. JPEG is what almost every phone camera saves, PNG is what a screenshot is, and some Android phones save WebP. iPhones take HEIC photos, but when a browser uploads one it sends a JPEG, so HEIC doesn't need its own entry. A PDF, a video or an SVG is refused. The type is the one Active Storage reads from the file's first bytes, not from its name, so a PDF renamed `photo.jpg` is refused too. The field's `accept` attribute only narrows the file picker. The model is what refuses.

**How big can a photo be?**
10 MB each. A phone photo is between 2 and 6 MB, so 10 MB leaves room for a good camera without letting someone fill the disk with one upload. The message names the file and says how big it is, for example "Intake photos can be at most 10 MB each, and “wheel.jpg” is 11.1 MB".

**Why do new photos join the old ones instead of replacing them?**
Assigning photos to a record replaces the whole set, and an empty file field would delete all of them. The edit form doesn't send the field at all when no file is chosen, and the controller adds the chosen files to the photos already on file. If any file is refused, nothing is saved: not the refused file, and not the valid ones sent with it.

**How is one photo removed?**
Each photo has its own Remove button (a `DELETE` with a confirmation), on the repair's page and below its edit form. It purges the photo, which deletes the attachment row, the blob row, the file, and the thumbnails made from it. The other photos stay. The page you pressed it on is the page you go back to.

**What happens to the photos when a repair is deleted?**
The attachment rows and the rich-text row go with the repair. The blobs and the files are purged right after, in a background job.

**How big are the thumbnails?**
Two sizes, both written once in `Repair`: 96×72 for the lists, cropped to fill the box so every row lines up whatever the photo's shape, and up to 960×720 on the repair's page, shrunk but not cropped. Both drop the camera's metadata, which can weigh more than a small thumbnail. A thumbnail weighs around 3 KB, where the original is a few MB. The original is downloaded only when you click a photo. A repair with no photo shows a grey "No photo" box of the same size, so its row stays aligned.

**Where does the diagnosis live now?**
It was a `text` column on `repairs`. It's now rich text stored by Action Text. A migration copied each existing diagnosis into the rich-text table (escaped, since it was plain text) and then removed the column. Rolling the migration back copies the plain text back. The lists show the first 50 characters of the diagnosis as plain text, on one line.

**Why is the editor's attach button hidden?**
A file attached inside the diagnosis would skip the type and size rules of the intake photos. Photos go in the "Intake photos" field, where they're checked.

## Lab 10: the JSON API

**How does a price travel?**
As a string with two decimals: `"8000.00"`. The column is an exact decimal, and a JSON number becomes a floating-point number in most clients, JavaScript included, which can't hold every amount exactly. A string carries the same digits the database has. The page turns it into a number only to format it. This applies to every price in the API: a service's price, a line's charged price and a repair's total.

**Why are the prices in pesos now?**
The personal page shows prices as Chilean pesos (`$8.000`, no decimals), because that's what a shop here charges in. The seed had prices that looked like dollars (12.00, 45.00), which would have read as `$12` and `$45`. The seed now uses peso amounts, for both the list prices and the hard-coded charged prices of old repairs, keeping the same relationships (an old repair still charged less than today's price). The column stays `decimal(8,2)`, which holds up to 999,999.99. The records pages still print prices with a `$` and two decimals: Lab 10 says the pages don't change.

**What's the highest price a service can have?**
999,999.99, the most `decimal(8,2)` holds. Before this lab a bigger price got past the validations and the database refused it with an error page. Now the model refuses it with a sentence ("Price can be at most 999999.99"), on the form and in the API.

**What does "how many repairs the service has been charged on" count?**
Distinct repairs among the service's lines, so a repair that charged the same service twice counts once. The database counts them in the same query that reads the services (`LEFT JOIN` and `COUNT(DISTINCT ...)`), so the price list is one query however many services and lines there are.

**How is the customer's answer shown?**
`Repair#customer_answer` turns the state into the lifecycle's words: "approved" from the approval on, "declined" if they said no, and nothing (`null`) while the quote is unanswered. It returns the enum's own values, so no state name is written as a string.

**What does the repair document leave out?**
The phone, every foreign key, the mechanic, the reported problem and the diagnosis, the photos, the bike's color, the timestamps and the payments. Accounting needs what was charged, to whom, for which bike and when; the reasons for each one are in `docs/api.md`.

**Which routes need the token?**
The base controller of the API asks for it before every action, and `Api::V1::ServicesController` skips that for `index` and `show`. A new controller of the API needs the token unless it says otherwise, so forgetting a line closes a route instead of opening it.

**What does an unknown path under `/api/v1` answer?**
A JSON `404`, like a missing record, and so does `/api/v1` itself. Without the catch-all route at the end of the API's routes, Rails would answer with its HTML error page.

**Where are the errors answered?**
In the base controller, with `rescue_from`: a missing record is a `404`; a body the API can't read, and a `state` filter that isn't a state, are a `400`. The repairs controller doesn't render the filter's error itself: it raises `ActionController::BadRequest` with the message, and the base controller answers it. The `401` comes from the token check, and the `422` from the action that saves, since only it knows the record that failed.

**Why does a service's name drop null bytes?**
PostgreSQL can't store a null byte in a string, so a name with one (easy to send through the API) made the database raise and the app answer `500`. The name's normalization now removes it, along with the extra spaces it already removed.

**Where does the token live, and how does someone else set theirs?**
In the encrypted credentials, as `api_token`. Mine is in `config/credentials.yml.enc`, whose key (`config/master.key`) isn't committed. Someone who clones the repository can't decrypt that file, so the README has them create development credentials (`bin/rails credentials:edit --environment development`), which Rails reads instead of the main file in development. `.gitignore` already ignores the key that command creates.

**Which origins can read the API?**
The published personal page and `http://localhost:8000`, only with `GET`, and only the price list. The page doesn't use the token, so the routes that need it aren't opened to any origin.

## Lab 11: accounts for the workshop

**Which role is the default, and why mechanic?**
The default has to be the role that can do the least. In the workshop, the owner runs everything: the price list, the staff, the money. The person at the counter talks to customers: takes the bikes in, has their names and phones, gives the quote and takes the payment. A mechanic works on the bike: reads the repair, writes the diagnosis and moves it along. The mechanic doesn't need the customers' phones, the price list or the payments, so mechanic is the role with the fewest permissions, and a new account starts there. The owner gives someone `counter` or `owner` from the console. (Since Lab 12 the roles decide what each account can do; see `docs/permissions.md`.)

**Why isn't the default `counter`, since the counter is who signs up most?**
Because a default that turns out too small is fixed by the owner in one line, and a default that turns out too big gives a stranger who signed up the customers' phone numbers.

**How is an email address unique without regard to case?**
Twice. The model stores it stripped and lowercased (the generator's `normalizes`) and validates uniqueness case-insensitively, which gives the sentence on the form. The database has a unique index on `lower(email_address)` instead of the generator's index on the column, so a row written around the model (SQL, `insert_all`) with `Ana@Wheelhouse.cl` is refused too.

**Why 10 characters?**
The lab's minimum, and enough that a word or a date isn't a password. The maximum is bcrypt's 72 bytes, which `has_secure_password` already checks. The message says the number: "Password must be at least 10 characters long". `User::PASSWORD_MIN_LENGTH` is the one place it's written; the forms read it for their hint.

**What changed in the generated code?**
The files stay where the generator put them; their views were rewritten with Bootstrap and the application's layout. Behavior changes, all in the generated controllers:

- A failed sign-in renders the form again with `422` and the address kept, like any refused form, instead of redirecting. The message is the same for a wrong address and a wrong password.
- The password form refuses a blank password. `has_secure_password` ignores a blank one, so the generated code answered "Password has been reset" and changed nothing. A refused new password renders the form with `422` and the messages next to the fields instead of redirecting with one sentence.
- `PasswordsController` lists its open actions by name instead of opening the whole controller, and `resource :session` only has the three actions it uses, so `GET /session` is a `404`, not an error.
- The messages are worded for the workshop, and the reset email says it's from Wheelhouse.

The rate limit on signing in (10 tries in 3 minutes) is the generator's and stays. The sign-up and the password request have the same limit.

**Which pages are open, and where is that said?**
`ApplicationController` includes the generator's `Authentication`, so every page asks for a session. Each open page is opened in its own controller, by action: `ShopController` opens `services`, `Catalog::ServicesController` opens `index` and `show`, and the sessions, passwords and registrations controllers open the actions a visitor needs. The home, visiting and about pages are closed: the owner said nothing but the price list is public. The API isn't affected: its controllers inherit from `ActionController::API`, not from `ApplicationController`.

**What does a visitor see on the open pages?**
The navbar has the price list and "Sign in", and the logo goes to the price list. A service's page shows its price but not the repairs that charged it, since those link to closed pages. The New/Edit/Delete buttons only show to someone signed in.

**Why can't sign-up choose a role?**
Its permitted list is `email_address`, `password` and `password_confirmation`. A hand-written `user[role]=owner` or `user[employee_id]=1` is dropped by `params.expect`, and the account gets the default role and no staff member. No page lists, edits or deletes accounts.

**Who took the repair in, and why can it be empty?**
`repairs.taken_in_by_id` references `users`. `create` sets it from `Current.user`; it's not in the form or the permitted list, and `update` never touches it, so an edit by someone else keeps the original. It allows `NULL` for repairs from before accounts existed. In the seed, the two repairs from last year have nobody. If an account is ever deleted (only from the console), its repairs keep their history with nobody (`dependent: :nullify`).

**Why can't a staff member with an account be removed?**
The account would be left pointing at nobody, and the person could still sign in. `Employee has_one :user, dependent: :restrict_with_error` refuses it, and the refusal shows on the staff member's page like every other refused delete. It's declared before `has_many :repairs`, so the check runs before their repairs would be unassigned.

**How do emails leave, and where do they go?**
Both emails go through `deliver_later`, so a job sends them after the page has answered. In development the job runs in the app's own process (Active Job's default adapter), so there's no queue to start. Action Mailer writes each email to `tmp/mails/<address>` (`delivery_method = :file`) instead of handing it to a mail server, and `raise_delivery_errors` is on, so an email that can't be written is an error in the log rather than silence. No provider, SMTP server or credential is involved. The emails' text is plain ASCII, so the file holds the link exactly as it should be copied.

**What does the navbar cost?**
Three queries on every page for someone signed in: the session, the account and its staff member. The lists of repairs also preload who took each repair in (two queries), so the counts stay fixed whatever the number of repairs or accounts.

## Lab 12: who may do what

The rules are in [`docs/permissions.md`](permissions.md), one table per resource. These are the decisions behind them.

**How is every action checked?**
`ApplicationController` includes `Pundit::Authorization` and runs `verify_authorized` after every action, and `verify_policy_scoped` after every `index`. An action that never asks its policy raises `Pundit::AuthorizationNotPerformedError`, and an index that isn't built from `policy_scope` raises too. They're in `ApplicationController`, so a new controller is covered without writing anything in it (`test/integration/authorization_guard_test.rb` proves it with a controller that forgets). The checks raise in every environment, not only development.

**Which actions skip the check, and why?**
Only the ones a person reaches before having an account to judge:

| Action | Why it's public |
| --- | --- |
| `SessionsController#new`, `#create` | Signing in: the visitor has no account yet. |
| `RegistrationsController#new`, `#create` | Signing up: the visitor has no account yet. |
| `PasswordsController#new`, `#create`, `#edit`, `#update` | A forgotten password: the person can't sign in, and the link in the email is what identifies them. |

Each skips with `skip_after_action :verify_authorized, only: [...]`, naming its actions. Signing out isn't on the list: it asks `SessionPolicy#destroy?`. The public price list isn't on it either: `ShopPolicy#services?` and `ServicePolicy#index?`/`#show?` answer yes to a visitor, so those pages still ask.

**Which pages have no model, and what do they ask?**
The shop's pages ask `ShopPolicy` (`authorize :shop`), the Lab 4 mockups ask `MockupPolicy`, and signing out asks `SessionPolicy`. These policies have no record; they check who is asking. The home, visiting and about pages and the mockups are open to every account.

**Why is there a policy for payments, if the lab lists five resources?**
Payments have pages (`index` and `show`), and every action must ask a policy. Payments are money, so the owner and the counter read them and a mechanic doesn't; a repair's page shows its payments only to them.

**What does the base policy do?**
`ApplicationPolicy` answers no to every action and its scope returns `none`. A policy opens only what it writes. The role checks (`owner?`, `counter?`, `mechanic?`, `signed_in?`) call the enum's methods on the account, so no role is written as a string in a policy. A visitor is `nil`, and every role check is false for it.

**Who is the user a policy sees?**
`pundit_user` returns `Current.user`, after resuming the session (public actions skip the authentication filter, so a signed-in owner on the public service list is still recognized and sees the New button). The controller hands it in; no policy reads the session, `params` or `Current`.

**What is a mechanic's "own" repair?**
One whose `mechanic_id` is the `employee_id` of the mechanic's account. `RepairPolicy#show?` and `RepairPolicy::Scope` say the same thing (`test/policies/repair_policy_test.rb` checks every account against every repair). A mechanic's account with no staff member gets `none`, not `where(mechanic_id: nil)`, which would have handed it every unassigned repair.

**A mechanic opens another mechanic's repair by its id: 403 or 404?**
`403`, for the page and for the edit form alike: `set_repair` finds the repair and authorizes it in the same line. A `404` would hide whether the repair exists, but the ids are sequential, so it would hide little.

**Why can't the counter edit a handed-back repair?**
A completed repair has been paid for and given back; changing it changes the shop's history. Only the owner corrects one. The counter can still move a repair to `completed` and fill in the hand-back time, which is the last edit it makes.

**Why can a mechanic add intake photos but not remove them?**
The lab gives mechanics the state, the diagnosis and adding photos. Removing a photo deletes the file, so it stays with whoever may change every field: the owner, and the counter while the repair isn't handed back (`RepairPolicy#remove_intake_photo?`).

**How does the form know which fields to draw?**
`RepairPolicy#permitted_attributes` returns the list for the person: every field for the owner and the counter, `status`, `diagnosis` and `intake_photos` for a mechanic. The controller passes it to `params.expect`, with no conditional on the role. The form draws a field only if `writes?(repair, :field)` (a helper that reads the same list) says so. A field sent anyway, from DevTools or a script, isn't in the list and is dropped like any unpermitted parameter, and the save goes on.

**How do the views avoid checking roles?**
They ask the policy: `policy(Customer).new?`, `policy(@repair).destroy?`, `policy(Repair).index?`. The navbar builds the Records menu from the models whose `index?` is true. `link_if_allowed` writes a bike's or customer's name as a link only if `show?` allows it, which is how a mechanic sees the bike and the customer of their repair without a link to a page they can't open.

**What does a refused request look like?**
`rescue_from Pundit::NotAuthorizedError` renders `errors/forbidden` with status `403`, in the application's layout. Every write is authorized before it saves or destroys, so a refused request writes nothing. A refused form submission (a Delete button, a forged edit) gets the same page: Turbo renders a `4xx` response in place of the form, as it does with a `422`. A visitor never gets there, because the authentication filter sends them to sign in first.

**Why do the repairs index filters exist?**
The lab asks that a mechanic filtering by state, or looking at the overdue repairs, sees only their own. The index now has both filters (`?state=` with a state's value, `?overdue=1`), and both are chained on the scope, so they narrow it.

**What does the authorization cost?**
Nothing in queries: the policies decide from the account (already loaded for the navbar) and the record on the page. The repairs index runs 16 queries for the owner, the counter and a mechanic, with or without filters, and the same with twice the repairs.

**Brakeman**
`bin/brakeman` runs with `--ensure-latest`, so it refused to run on 8.0.6 once 8.1.0 was out. The gem is updated to 8.1.0, which reports no warnings, so there is no ignore file.

