# The Wheelhouse API

A JSON API for programs that are not a browser: the shop's website reads the price list, and the
accounting program reads the repairs. Every route is under `/api/v1`, and every response is JSON,
including the errors.

## Routes

| Verb | Path | Token | Statuses |
| ---- | ---- | ----- | -------- |
| `GET` | `/api/v1/services` | No | `200` |
| `GET` | `/api/v1/services/:id` | No | `200`, `404` |
| `POST` | `/api/v1/services` | Yes | `201`, `400`, `401`, `422` |
| `GET` | `/api/v1/repairs` | Yes | `200`, `400`, `401` |
| `GET` | `/api/v1/repairs/:id` | Yes | `200`, `401`, `404` |

Any other path or verb under `/api/v1` answers `404` in the error shape below.

The token travels in the `Authorization` header, with the `Bearer` scheme:

```
Authorization: Bearer <token>
```

The token is checked before anything else, so a request without it gets the `401` even if it would
also have been a `400` or a `404`.

## Documents

### A service

`GET /api/v1/services/1` answers this document. `GET /api/v1/services` answers a list of them, ordered
by name, and `POST /api/v1/services` answers the new one.

```json
{
  "id": 1,
  "name": "Flat Tyre Repair",
  "price": "20.00",
  "repairs_count": 3
}
```

`repairs_count` is how many repairs the service has been charged on. A service charged twice on one
repair counts once.

### Registering a service

`POST /api/v1/services` reads `name` and `default_price`, the names the validation messages use. Any
other attribute is dropped. A new service is always active.

```json
{
  "service": {
    "name": "Wheel Wash",
    "default_price": "12.50"
  }
}
```

The `201` carries the URL of the new service in its `Location` header.

### A repair

```json
{
  "id": 7,
  "state": "picked_up",
  "came_in_on": "2026-10-01",
  "promised_on": "2026-10-05",
  "picked_up_on": "2026-10-06",
  "bike": {
    "brand": "Giant",
    "model": "Escape",
    "serial_number": "SN-1001"
  },
  "customer": {
    "name": "Ana Rojas"
  },
  "lines": [
    { "service": "Flat Tyre Repair", "price": "20.00" },
    { "service": "Chain Replacement", "price": "22.50" }
  ],
  "total": "42.50",
  "overdue": false,
  "customer_answer": "approved"
}
```

- `picked_up_on` is the day the bike was handed back, or `null`.
- `lines[].price` is the price charged on that repair, not the current price of the service.
- `overdue` is `true` when the promised day has passed and the bike has not been picked up.
- `customer_answer` is the customer's answer to the estimate: `approved`, `rejected` or `pending`.
- `state` is one of `dropped_off`, `awaiting_estimate_approval`, `in_progress`, `ready_for_pickup`,
  `picked_up`.

### A collection of repairs

`GET /api/v1/repairs` answers a list of repair documents, ordered by the promised day. It has no pages.
`GET /api/v1/repairs?state=picked_up` answers only the repairs in that state.

```json
[
  {
    "id": 7,
    "state": "picked_up",
    "came_in_on": "2026-10-01",
    "promised_on": "2026-10-05",
    "picked_up_on": "2026-10-06",
    "bike": { "brand": "Giant", "model": "Escape", "serial_number": "SN-1001" },
    "customer": { "name": "Ana Rojas" },
    "lines": [
      { "service": "Flat Tyre Repair", "price": "20.00" }
    ],
    "total": "20.00",
    "overdue": false,
    "customer_answer": "approved"
  }
]
```

### An error

Every error is an object with one key, `errors`, whose value is a list of strings.

```json
{
  "errors": [
    "Name has already been taken",
    "Default price must be greater than 0"
  ]
}
```

| Status | When |
| ------ | ---- |
| `400` | The body carries nothing the API can read, or `state` has a value that does not exist. |
| `401` | The token is missing or wrong, on a route that needs it. |
| `404` | There is no record with that id, or no such route. |
| `422` | A validation failed. The messages are the sentences the form shows. |

## Decisions

### A price travels as a string

Every price in every document is a string with two decimals, such as `"20.00"`: `price` on a service,
`price` on a line and `total` on a repair. The database stores prices as exact decimals, and a JSON
number would be read as a floating-point number by most clients. Accounting needs the exact value, and
the two decimals are kept. A client that does arithmetic converts the string with its own decimal type.

### What a repair leaves out

The document carries what accounting needs to record a charge, and nothing else.

- **The customer's phone**: accounting does not call customers, and it is personal data.
- **The mechanic**: who did the work does not change what was charged.
- **The diagnosis and the intake photos**: they describe the workshop's work, not the charge, and they
  can be long or heavy.
- **The bike's colour**: brand, model and serial number already identify the bike.
- **`quoted_at`, `completed_at`, `created_at` and `updated_at` as timestamps**: the days that matter are
  in `came_in_on`, `promised_on` and `picked_up_on`.
- **Foreign keys**: the bike, the customer and the services are inside the document, by name.

### What a service leaves out

The price list does not carry `active`, and it lists every service, as it answers "the collection of
services". The timestamps are left out because no client of the price list needs them.
