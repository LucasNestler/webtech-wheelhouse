# Wheelhouse Bicycle Repair Shop

## Prerequisites

- **Ruby:** `4.0.4`
- **Rails:** `8.0.x`
- **Node.js:** `26.1.0` (with `npm`)
- **Yarn:** `1.22.x`
- **PostgreSQL:** Running locally with a superuser role matching your current system user with database creation permissions (postgress needs the same user as the os user)
- **libvips:** needed to make the photo thumbnails (Active Storage variants). Install it before running the app:
  - Ubuntu / Debian / WSL: `sudo apt-get install -y libvips`
  - macOS (Homebrew): `brew install vips`
  - Check it with `vips --version`

## Specification Documents
All initial analysis and project specification documentation are located in the [`docs/`](./docs/) directory.

## Setup Instructions

1. **Clone the repository:**
   `git clone https://github.com/LucasNestler/webtech-wheelhouse`
2. **Navigate to the directory:**
   `cd webtech-wheelhouse`
3. **Install Gem dependencies:**
   `bundle install`
4. **Install Node dependencies:**
   `npm install`
5. **Create, migrate and seed the database** (the seed attaches the sample photos in `db/seeds/` and writes the files to `storage/`; running it again resets the data, it does not duplicate it):
   `bin/rails db:prepare`
   If the database already existed, run `bin/rails db:seed` as well.
6. **Build CSS:**
   `npm run build:css`
7. **Start the development server:**
   `bin/dev`

Open <http://localhost:3000>. Every page except the price list asks you to sign in, with one of the accounts below. After that, <http://localhost:3000/repairs> shows a thumbnail and the start of the diagnosis on each row.

## Accounts

The seed creates these accounts. **They exist only in development, on your machine**, and every run of the seed resets them. Customers do not have accounts.

| Email address | Password | Role | Member of the staff |
| ------------- | -------- | ---- | ------------------- |
| `robin@wheelhouse.example` | `robin-owner-2026` | owner | Robin Hale |
| `sam@wheelhouse.example` | `sam-lead-wrench` | mechanic | Sam Vasquez |
| `alex@wheelhouse.example` | `alex-junior-spokes` | mechanic | Alex Chen |
| `jordan@wheelhouse.example` | `jordan-true-wheels` | mechanic | Jordan Taylor |
| `pat@wheelhouse.example` | `pat-front-counter` | counter | Pat Morgan |
| `guest@wheelhouse.example` | `guest-new-account` | mechanic (the default) | None |

Anyone can also create an account at <http://localhost:3000/registration/new>. It always gets the default role. To change the role of an account or join it to a member of the staff, use the console, `bin/rails console`:

`User.find_by(email_address: "guest@wheelhouse.example").update!(role: :counter, mechanic: Mechanic.find_by(name: "Pat Morgan"))`

## Reading the emails

No email leaves your machine, and nothing about email needs to be configured. Every email the application sends (the password reset and the welcome) goes to a local inbox at <http://localhost:3000/letters>, which exists only in development and keeps the files in `tmp/letter_opener`.

To try a forgotten password: click **Forgot password?** on the sign-in page, enter an address from the table, open the inbox and follow the link in the email. The link works for 15 minutes.

To see the designs of the emails without sending any, open <http://localhost:3000/rails/mailers>.

## The API

Wheelhouse also answers a JSON API under `/api/v1`. Routes, documents and decisions are in [`docs/api.md`](./docs/api.md).

### Set the token

Reading repairs and registering a service need a token, kept in the encrypted credentials under the key `api_token`. `config/credentials.yml.enc` is encrypted with a `config/master.key` that is not in the repository, so a fresh clone creates its own credentials:

1. Remove the credentials you cannot read:
   `rm config/credentials.yml.enc`
2. Generate a token and copy it:
   `bin/rails secret`
3. Open new credentials (this also creates your `config/master.key`):
   `EDITOR=nano bin/rails credentials:edit`
4. Add this line, with your token, then save and close:
   `api_token: <your token>`
5. Restart the server, and put the token in a variable of your terminal for the examples below:
   `export API_TOKEN=<your token>`

Until a token is set, the routes that need it answer `401`. The rest of the application works without one. If you already have the project's `config/master.key`, skip the steps above and read the token with `bin/rails credentials:show`.

### Ask the API from the terminal

The server has to be running (`bin/dev`).

The price list is public:

`curl http://localhost:3000/api/v1/services`

Repairs need the token:

`curl -H "Authorization: Bearer $API_TOKEN" http://localhost:3000/api/v1/repairs`

Only the repairs in one state:

`curl -H "Authorization: Bearer $API_TOKEN" "http://localhost:3000/api/v1/repairs?state=picked_up"`

Register a service:

`curl -i -X POST -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json" -d '{"service":{"name":"Wheel Wash","default_price":"12.50"}}' http://localhost:3000/api/v1/services`

## The published page

The [published page](https://lucasnestler.github.io/webtech-lab-01/) has a **Price List** section that reads this API from the browser. Its code is in [`webtech-lab-01`](https://github.com/LucasNestler/webtech-lab-01).

**The API has to run on port 3000** for the page to find it, which is what `bin/dev` uses. Start it, then open the page: the section shows the services from your database. Without the API running, the section says the price list is not answering.

**Allow the page to reach your computer.** Chrome and Firefox block a public site from reaching `localhost` until you give it permission, and the section shows the same "not answering" sentence until you do. The API receives no request while it is blocked.

The API accepts browser requests from two origins only: `https://lucasnestler.github.io`, and `http://localhost:5500` for developing the page. To develop it, serve a clone of `webtech-lab-01` on that port with `python3 -m http.server 5500`, and open <http://localhost:5500>.

## Tests

`bin/rails test`
