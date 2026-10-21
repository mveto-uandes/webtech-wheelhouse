# The Wheelhouse API

A JSON API for programs that aren't a browser: the shop's website, which shows the price list, and
the accounting program, which reads the repairs. Every route is under `/api/v1`, and every answer,
errors included, is JSON (`Content-Type: application/json`).

## Routes

| Verb | Path | Token | Answers |
| --- | --- | --- | --- |
| `GET` | `/api/v1/services` | no | `200` |
| `GET` | `/api/v1/services/:id` | no | `200`, `404` |
| `POST` | `/api/v1/services` | yes | `201`, `400`, `401`, `422` |
| `GET` | `/api/v1/repairs` | yes | `200`, `400` (unknown `?state=`), `401` |
| `GET` | `/api/v1/repairs/:id` | yes | `200`, `401`, `404` |

Any other path or verb under `/api/v1`, `/api/v1` itself included, answers `404` with the error document. When a route needs the
token and the token is missing or wrong, the `401` comes before anything else, so a missing repair
answers `401`, not `404`, to someone without the token.

### The token

The routes marked "yes" need this header:

```
Authorization: Bearer <token>
```

A token in the query string or in the body is ignored, and the answer is `401`. The token is stored
in the app's encrypted credentials as `api_token` (the README says how to set it).

### Filtering repairs by state

`GET /api/v1/repairs?state=quoted` answers only the repairs in that state. The states are `received`,
`diagnosing`, `quoted`, `approved`, `declined`, `in_repair`, `ready_for_pickup` and `completed`. Any
other value, an empty one included, answers `400` with a message that lists them.

### Registering a service

```
POST /api/v1/services
Content-Type: application/json
Authorization: Bearer <token>

{ "service": { "name": "Disc brake bleed", "price": "22000.00" } }
```

Only `name` and `price` are read. Any other key (an `id`, a `created_at`) is dropped. The answer is
`201` with the new service's document, and its `Location` header is the service's URL in the API:
`Location: http://localhost:3000/api/v1/services/27`. The price can be sent as a string or as a
number.

The attributes can also be sent without the `service` key (`{ "name": ..., "price": ... }`): Rails
wraps them under `service` before the controller reads them.

An empty body, a body that isn't JSON, or a body with no `name` or `price` answers `400`. A service
the validations refuse answers `422` with the same sentences the form on the records pages shows.

## Documents

### A service

The same shape in `index` (one per service), `show` and `create`:

```json
{
  "id": 1,
  "name": "Flat tire repair",
  "price": "8000.00",
  "repairs_count": 2
}
```

`repairs_count` isn't a column: it's how many repairs the service has been charged on. A repair
that charged the same service twice counts once. A service that was just created has `0`.

The collection, `GET /api/v1/services`, is a list of these documents, ordered by name:

```json
[
  { "id": 10, "name": "Bearing overhaul (hubs/bottom bracket)", "price": "40000.00", "repairs_count": 0 },
  { "id": 17, "name": "Bottom bracket replacement", "price": "40000.00", "repairs_count": 0 },
  { "id": 4, "name": "Brake adjustment", "price": "12000.00", "repairs_count": 0 }
]
```

### A repair

```json
{
  "id": 12,
  "state": "completed",
  "received_on": "2026-10-09",
  "promised_on": "2026-10-11",
  "handed_back_on": "2026-10-11",
  "customer_answer": "approved",
  "overdue": false,
  "customer": { "name": "Agustín Bravo" },
  "bike": { "make": "Trek", "model": "Marlin 5", "serial_number": "TRK-MAR-1102" },
  "lines": [
    { "service": "Pedal installation", "charged_price": "3000.00" },
    { "service": "Kickstand installation", "charged_price": "6000.00" },
    { "service": "Rack installation", "charged_price": "15000.00" }
  ],
  "total": "24000.00"
}
```

- `state` is one of the eight states listed above.
- `received_on` is the day the bike came in. `promised_on` is `null` until the shop promises a day.
  `handed_back_on` is `null` until the bike leaves the shop. Dates are `YYYY-MM-DD`.
- `customer_answer` is the customer's answer to the quote, named as the lifecycle names it:
  `"approved"` from the approval on (approved, in_repair, ready_for_pickup, completed), `"declined"`
  if they said no, and `null` while the quote hasn't been answered (received, diagnosing, quoted).
- `overdue` is `true` when the promised day has passed and the bike is still in the shop.
- `lines` are the services charged, in the order they were added, each with the price charged on
  this repair. That can differ from today's list price: a repair from last year keeps last year's
  price.
- `total` is the sum of the charged prices. A repair with no lines has a total of `"0.00"`.

### A collection of repairs

`GET /api/v1/repairs` is a list of repair documents, ordered by promised day (repairs without one
last). It has no pages: the list is every repair, or every repair in the state asked for. Two of
the seed's repairs, as an example:

```json
[
  {
    "id": 16,
    "state": "completed",
    "received_on": "2025-06-03",
    "promised_on": "2025-06-08",
    "handed_back_on": "2025-06-08",
    "customer_answer": "approved",
    "overdue": false,
    "customer": { "name": "Antonia Vergara" },
    "bike": { "make": "Specialized", "model": "Sirrus X", "serial_number": "SPZ-SIRX-3001" },
    "lines": [ { "service": "Wheel replacement", "charged_price": "40000.00" } ],
    "total": "40000.00"
  },
  {
    "id": 5,
    "state": "quoted",
    "received_on": "2026-10-18",
    "promised_on": "2026-10-22",
    "handed_back_on": null,
    "customer_answer": null,
    "overdue": false,
    "customer": { "name": "Benjamín Castro" },
    "bike": { "make": "Cannondale", "model": "Quick 4", "serial_number": "CAN-Q4-4001" },
    "lines": [
      { "service": "Rear derailleur hanger straightening", "charged_price": "10000.00" },
      { "service": "Gear/derailleur adjustment", "charged_price": "15000.00" }
    ],
    "total": "25000.00"
  }
]
```

### An error

Every error, whatever its status, is an object with one key, `errors`, holding a list of sentences:

```json
{ "errors": ["Name can't be blank", "Price can't be blank", "Price is not a number"] }
```

| Status | When | Example message |
| --- | --- | --- |
| `400` | The body is empty, isn't JSON, or has no attributes of a service. The `state` filter isn't a state. | `The body isn't valid JSON.` |
| `401` | The route needs the token and the `Authorization` header is missing or carries another token. | `This route needs a valid token in the Authorization header: Bearer <token>.` |
| `404` | There's no record with that id, or no such route. | `There's no service with id 999.` |
| `422` | A validation refused the service. | `Name is already on the price list` |

A `401` also carries the header `WWW-Authenticate: Bearer realm="Wheelhouse"`.

## Decisions

**How a price travels: as a string with two decimals.** `"8000.00"`, never `8000` or `8000.0`. The
column is `decimal(8,2)`, an exact amount. A JSON number is read as a floating-point number by most
clients (JavaScript included), which can't hold every decimal amount exactly. As a string, the
client gets the same digits the database has and decides how to read them. Every price in every
document travels this way: a service's `price`, a line's `charged_price` and a repair's `total`.

The shop charges in Chilean pesos, which have no decimals in practice, but the column accepts cents,
so the string always has two. The website shows the price as pesos with no decimals (`$8.000`).

**What the repair document leaves out, and why.** The accounting program bills repairs. It needs
what was charged, to whom, for which bike and when. So the document leaves out:

- **The customer's phone.** It's personal data, and accounting doesn't call anyone.
- **Every foreign key** (`bike_id`, `mechanic_id`, the line's `service_id`). A program can't do
  anything with our row numbers. The bike, the customer and the services are inside the document,
  by name.
- **The mechanic.** Who did the work doesn't change what was charged.
- **The reported problem and the diagnosis.** They're the workshop's notes, written for the counter
  and the mechanics, and the diagnosis is formatted HTML.
- **The intake photos.** They're evidence of the bike's condition, not of the bill.
- **The bike's color and the timestamps** (`created_at`, `updated_at`). The serial number already
  identifies the bike, and the days that matter are the three dates in the document.
- **Payments.** The document says what was charged. What was paid is a separate record, and the
  counter doesn't record payments in the app yet.

**Which origins can read the API from a browser.** Only the personal page that shows the price list:
`https://mveto-uandes.github.io` (published) and `http://localhost:8000` (while developing). Only
`GET`, and only on `/api/v1/services`. The routes that need the token aren't opened to any origin.
A request without an `Origin` header (curl, the accounting program) isn't affected by any of this.
