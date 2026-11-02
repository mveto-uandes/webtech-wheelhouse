# Who may do what

What each role may do in Wheelhouse, as the policies in `app/policies/` decide it. A cell says
**yes**, **no**, or under which condition. A refused request answers `403` with a page that says
so; a visitor with no session is sent to sign in instead (except on the public rows).

- **Own repair**: a repair whose mechanic is the staff member the account belongs to. A mechanic's
  account that belongs to no staff member has no own repairs.
- **Handed back**: a repair in the last state of the lifecycle, `completed`.
- An account made at Sign up has the role `mechanic` and no staff member, so it has a mechanic's
  permissions over no repairs.

## Services (`ServicePolicy`)

| Action | Owner | Counter | Mechanic | Visitor |
| --- | --- | --- | --- | --- |
| List the services (`index`) | yes | yes | yes | yes |
| Open a service (`show`) | yes | yes | yes | yes |
| Add a service (`new`, `create`) | yes | no | no | no |
| Edit a service (`edit`, `update`) | yes | no | no | no |
| Delete a service (`destroy`) | yes | no | no | no |

A service's page lists the repairs that charged it, filtered by the repairs scope: each person
sees only the lines of repairs they may read, and a visitor sees none.

## Staff (`EmployeePolicy`)

| Action | Owner | Counter | Mechanic |
| --- | --- | --- | --- |
| List the staff (`index`) | yes | yes | yes |
| Open a staff member (`show`) | yes | yes | yes |
| Add a staff member (`new`, `create`) | yes | no | no |
| Edit a staff member (`edit`, `update`) | yes | no | no |
| Remove a staff member (`destroy`) | yes, unless they have an account | no | no |

A staff member's page lists their repairs filtered by the repairs scope: a mechanic sees their
own there, and nothing on another mechanic's page.

## Customers (`CustomerPolicy`)

| Action | Owner | Counter | Mechanic |
| --- | --- | --- | --- |
| List the customers (`index`) | yes | yes | no |
| Open a customer (`show`) | yes | yes | no |
| Add a customer (`new`, `create`) | yes | yes | no |
| Edit a customer (`edit`, `update`) | yes | yes | no |
| Delete a customer (`destroy`) | yes, if they have no bikes | no | no |

## Bikes (`BikePolicy`)

| Action | Owner | Counter | Mechanic |
| --- | --- | --- | --- |
| List the bikes (`index`) | yes | yes | no |
| Open a bike (`show`) | yes | yes | no |
| Add a bike (`new`, `create`) | yes | yes | no |
| Edit a bike (`edit`, `update`) | yes | yes | no |
| Delete a bike (`destroy`) | yes, if it has no repairs | no | no |

On a repair's page, the bike and its customer are shown to everyone who may read the repair, and
are links only for those who may open them (the owner and the counter).

## Repairs (`RepairPolicy`)

| Action | Owner | Counter | Mechanic |
| --- | --- | --- | --- |
| List the repairs (`index`) | every repair | every repair | only their own |
| Open a repair (`show`) | every repair | every repair | only their own |
| Take a repair in (`new`, `create`) | yes | yes | no |
| Edit a repair (`edit`, `update`) | every repair | every repair not handed back | their own, not handed back |
| Remove an intake photo (`remove_intake_photo?`, `Catalog::IntakePhotosController#destroy`) | every repair | every repair not handed back | no |
| Delete a repair (`destroy`) | yes, if it has no payments | no | no |

The repairs index filters (by state, overdue only) narrow the scope; they never add repairs to it.
The same scope lists the repairs on a bike's page and on a staff member's page.

### Fields each role writes on a repair

| Field | Owner | Counter | Mechanic |
| --- | --- | --- | --- |
| State | yes | yes | yes |
| Diagnosis | yes | yes | yes |
| New intake photos | yes | yes | yes |
| Bike | yes | yes | no |
| Mechanic | yes | yes | no |
| Promised day | yes | yes | no |
| Hand-back time | yes | yes | no |
| Reported problem | yes | yes | no |
| Lines (service, charged price, remove) | yes | yes | no |
| Taken in by | no: always the account that took it in | no | no |

A field outside a person's list isn't drawn on their form, and if it's sent anyway it's dropped.

## Payments (`PaymentPolicy`)

| Action | Owner | Counter | Mechanic |
| --- | --- | --- | --- |
| List the payments (`index`) | yes | yes | no |
| Open a payment (`show`) | yes | yes | no |

No page creates, edits or deletes a payment. A repair's page shows its payments only to the owner
and the counter.

## The shop's pages (`ShopPolicy`, `MockupPolicy`)

| Page | Owner | Counter | Mechanic | Visitor |
| --- | --- | --- | --- | --- |
| Price list (`/services`) | yes | yes | yes | yes |
| Home, Visiting the Workshop, About | yes | yes | yes | no |
| Workflow mockups (`/mockups/*`) | yes | yes | yes | no |

## Accounts

| Action | Owner | Counter | Mechanic | Visitor |
| --- | --- | --- | --- | --- |
| Sign in, sign up, ask for and set a new password | yes | yes | yes | yes |
| Sign out (`SessionPolicy#destroy?`) | yes | yes | yes | no |
| List, edit or delete accounts | no page does this; only the seed or the console | | | |
