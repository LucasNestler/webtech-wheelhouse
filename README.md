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

## Tests

`bin/rails test`
