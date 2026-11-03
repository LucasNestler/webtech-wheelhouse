# Who May Do What

What each role may do, as the policies in `app/policies/` enforce it. A visitor with no session is sent to sign in, except on the pages this document marks as public. A request the policy refuses answers `403`.

**Handed back** means the repair is in the final state of the lifecycle, `Picked Up`. **Their own** means the repair's mechanic is the member of the staff joined to the account. An account with the role `mechanic` and no member of the staff has no repairs of its own, and reads none.

## Services

The price list is public: a visitor may read it too.

| Action | Owner | Counter | Mechanic |
|---|---|---|---|
| List (`index`) | Yes | Yes | Yes |
| Page (`show`) | Yes | Yes | Yes |
| New form (`new`) | Yes | No | No |
| Create (`create`) | Yes | No | No |
| Edit form (`edit`) | Yes | No | No |
| Update (`update`) | Yes | No | No |
| Delete (`destroy`) | Yes | No | No |

## Staff

| Action | Owner | Counter | Mechanic |
|---|---|---|---|
| List (`index`) | Yes | Yes | Yes |
| Page (`show`) | Yes | Yes | Yes |
| New form (`new`) | Yes | No | No |
| Create (`create`) | Yes | No | No |
| Edit form (`edit`) | Yes | No | No |
| Update (`update`) | Yes | No | No |
| Delete (`destroy`) | Yes, if the member of the staff has no account | No | No |

## Customers

| Action | Owner | Counter | Mechanic |
|---|---|---|---|
| List (`index`) | Yes | Yes | No |
| Page (`show`) | Yes | Yes | No |
| New form (`new`) | Yes | Yes | No |
| Create (`create`) | Yes | Yes | No |
| Edit form (`edit`) | Yes | Yes | No |
| Update (`update`) | Yes | Yes | No |
| Delete (`destroy`) | Yes | No | No |

## Bikes

| Action | Owner | Counter | Mechanic |
|---|---|---|---|
| List (`index`) | Yes | Yes | No |
| Page (`show`) | Yes | Yes | No |
| New form (`new`) | Yes | Yes | No |
| Create (`create`) | Yes | Yes | No |
| Edit form (`edit`) | Yes | Yes | No |
| Update (`update`) | Yes | Yes | No |
| Delete (`destroy`) | Yes | No | No |

## Repairs

| Action | Owner | Counter | Mechanic |
|---|---|---|---|
| List (`index`) | Yes, every repair | Yes, every repair | Yes, only their own |
| Page (`show`) | Yes, every repair | Yes, every repair | Only their own |
| New form (`new`) | Yes | Yes | No |
| Take in (`create`) | Yes | Yes | No |
| Edit form (`edit`) | Yes, every repair | Yes, if not handed back | Only their own, if not handed back |
| Update (`update`) | Yes, every repair | Yes, if not handed back | Only their own, if not handed back |
| Delete (`destroy`) | Yes | No | No |
| Remove an intake photo (`intake_photos#destroy`) | Yes, every repair | Yes, if not handed back | No |

The page of a repair shows its bike and its customer to everybody who may read it. They are links only for a person who may open the bike and the customer.

### The fields of a repair

| Field | Owner | Counter | Mechanic |
|---|---|---|---|
| State | Yes | Yes | Yes |
| Diagnosis | Yes | Yes | Yes |
| Add intake photos | Yes | Yes | Yes |
| Bike | Yes | Yes | No |
| Mechanic | Yes | Yes | No |
| Promised day | Yes | Yes | No |
| Quote accepted, quoted at, completed at, picked up at | Yes | Yes | No |
| Lines and their prices | Yes | Yes | No |
| Account that took it in | No, read from the session | No, read from the session | No, read from the session |

A field outside the list of the person is dropped, and the request goes on.

## Pages

| Action | Owner | Counter | Mechanic |
|---|---|---|---|
| Home (`home`) | Yes | Yes | Yes |
| Visiting the workshop (`visit`) | Yes | Yes | Yes |
| About us (`about`) | Yes | Yes | Yes |

## What does not ask a policy

Signing in, signing out, signing up and the pages of a forgotten password. [`docs/decisions.md`](./decisions.md) lists them with the reason. The API under `/api/v1` has its own token and no roles: see [`docs/api.md`](./api.md).

No page lists, edits or deletes accounts.
