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

Open <http://localhost:3000/repairs>: the repairs index shows a thumbnail and the start of the diagnosis on each row.

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

**The API has to run on port 3000** for the page to find it, which is what `bin/dev` uses. Start it, then open the page: the section shows the services from your database. If the browser asks whether the page may reach devices on your local network, allow it. Without the API running, the section says the price list is not answering.

The API accepts browser requests from two origins only: `https://lucasnestler.github.io`, and `http://localhost:5500` for developing the page. To develop it, serve a clone of `webtech-lab-01` on that port with `python3 -m http.server 5500`, and open <http://localhost:5500>.

## Tests

`bin/rails test`
