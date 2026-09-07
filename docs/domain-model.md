## Diagram

This is the DBML for the schema as it exists in `db/schema.rb` after Lab 5. It still compiles as
valid DBML in dbdiagram.io.

```dbml
Table customers {
  id integer [primary key]
  name varchar [not null]
  phone varchar [not null]
  created_at timestamp [not null]
  updated_at timestamp [not null]
}

Table bikes {
  id integer [primary key]
  customer_id integer [not null, ref: > customers.id]
  make varchar [not null]
  model varchar [not null]
  color varchar [not null]
  serial_number varchar [not null, unique, note: 'so two bikes that look the same dont get mixed up']
  created_at timestamp [not null]
  updated_at timestamp [not null]
}

Table employees {
  id integer [primary key]
  name varchar [not null]
  role varchar [not null, note: 'mechanic or counter']
  created_at timestamp [not null]
  updated_at timestamp [not null]
}

Table services {
  id integer [primary key]
  name varchar [not null, unique]
  price decimal [not null]
  created_at timestamp [not null]
  updated_at timestamp [not null]
}

Table repairs {
  id integer [primary key]
  bike_id integer [not null, ref: > bikes.id]
  mechanic_id integer [ref: >? employees.id, note: 'null until someone is assigned']
  status varchar [not null, default: 'received', note: 'received, diagnosing, quoted, approved, declined, in_repair, ready_for_pickup, completed']
  reported_problem text [not null]
  diagnosis text
  promised_on date [note: 'a day, not an instant; null until promised']
  handed_back_at timestamp [note: 'null until the bike is actually handed back']
  created_at timestamp [not null]
  updated_at timestamp [not null]
}

Table repair_line_items {
  id integer [primary key]
  repair_id integer [not null, ref: > repairs.id]
  service_id integer [not null, ref: > services.id]
  charged_price decimal [not null, note: 'copied from the service price at the time, can be discounted']
  created_at timestamp [not null]
  updated_at timestamp [not null]
}

Table payments {
  id integer [primary key]
  repair_id integer [not null, ref: > repairs.id]
  amount decimal [not null]
  method varchar [not null, note: 'cash, card, transfer']
  paid_at timestamp [not null]
  created_at timestamp [not null]
  updated_at timestamp [not null]
}
```

## Lifecycle

A repair moves through these states, in this order (mostly):

received -> diagnosing -> quoted -> approved (or declined) -> in_repair -> ready_for_pickup -> completed

Some transitions shouldn't be allowed and I think it's worth listing why:

- received straight to approved: doesn't make sense, nobody quoted anything yet so there's nothing to approve
- diagnosing to in_repair: same idea, can't start working before the customer said yes to a price
- declined to in_repair: if they said no, that's it for this repair. If they change their mind later I guess it would be a new repair
- completed to anything else: once it's done it's done, shouldn't be able to reopen it

## Which entity comes from which story

| Entity            | Story                                                                |
| ----------------- | --------------------------------------------------------------------- |
| customers         | Story 2                                                                |
| bikes             | Story 1, Story 11                                                      |
| employees         | Story 3, Story 7                                                       |
| repairs           | Story 2, 6, 7, 8, 13 (most of them really, this is the main table)     |
| services          | Story 12                                                               |
| repair_line_items | Story 4, this is where the cost actually comes from                   |
| payments          | Story 10                                                               |

## Two decisions I had to explain

**The thing and the copy of the thing.** So the owner mentioned that one time they mixed up two bikes because they were the same model and color (two blue Marlins). If I had just used one row per bike model with a quantity column, there would be no way to tell those two bikes apart, or know which specific one a repair belongs to. That's why every bike has its own row and its own serial_number, and repairs point at one exact bike_id, never just "a blue Marlin."

**Derived, or stored?** For whether a repair is late, I didn't add a column for that at all, it's just calculated by comparing promised_on to today whenever you look at the screen, no need to store it. But for charged_price on the line items, I did store it even though you could argue it's just copying services.price. I stored it anyway because prices go up every January and old repairs shouldn't suddenly cost more just because the list changed later. If I hadn't stored it, every past invoice would change every time the price list changes, which is wrong.

## Changes since Lab 3

- **`photos` table removed.** Lab 5 explicitly defers photo columns to Lab 9, so the table
  doesn't exist yet even though the owner mentioned photos.
- **`price_list_items` renamed to `services`, `repair_type` renamed to `name`.** Matches the
  language the lab and the `/services` page use ("the services table", "service names"), and
  reads more naturally once there's an actual `/services` page backed by it.
- **`repair_line_items.price_list_item_id` renamed to `service_id`.** Follows directly from the
  table rename above; still points at the same table, just under its new name.
- **`repairs.promised_at` renamed to `promised_on`.** It holds a day the shop promised the bike
  back, not a specific instant, so it belongs on the `_on`/date side of the naming convention,
  not `_at`/datetime.
- **`repairs.handed_back_at` added (new column, datetime, nullable).** The lab requires that "a
  repair that has not been handed back has no hand-back time" — there was no column in the Lab 3
  diagram that could hold this, and inferring it from `status == "completed"` alone would lose
  the actual moment the bike went out the door.
- **Every table gained `updated_at`.** Lab 3 only put `created_at` on most tables (and only
  `repairs` had `updated_at`). Lab 5 requires both on every table.
- **`NOT NULL` added on every mandatory column** (`customers.name`/`phone`,
  `bikes.make`/`model`/`color`/`serial_number`, `employees.name`/`role`,
  `services.name`/`price`, `repairs.reported_problem`, `repair_line_items.service_id`/
  `charged_price`, `payments.amount`/`method`/`paid_at`, etc.). The Lab 3 diagram didn't mark
  most columns as required; Lab 5 requires the database itself to refuse a row missing anything
  the shop's description makes mandatory.
- **Unique index added on `services.name`.** The lab requires a unique index on anything the
  description says can't repeat — two services can't share a name on the wall list, the same way
  two bikes can't share a serial number.
- **Decimal precision and scale added to every money column** (`services.price`,
  `repair_line_items.charged_price`, `payments.amount` — all `decimal(8, 2)`). The Lab 3 diagram
  just said `decimal` with no precision; Lab 5 requires it declared explicitly, and forbids
  `float` for money entirely.
- **`repairs.mechanic_id` stays nullable, as in Lab 3.** The diagram already noted "null until
  someone is assigned," and nothing in Lab 5 changes that — a repair can exist before a mechanic
  picks it up.
- **No foreign key constraints added.** The `_id` columns (`bikes.customer_id`,
  `repairs.bike_id`/`mechanic_id`, `repair_line_items.repair_id`/`service_id`,
  `payments.repair_id`) are plain integer columns today, same as the diagram implied, just
  without the `ref:` becoming an actual database constraint — that arrives with the Rails
  associations in Lab 7.
