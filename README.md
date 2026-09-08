# Wheelhouse Bicycle Repair Shop

## Prerequisites

- **Ruby:** `4.0.4`
- **Rails:** `8.0.x`
- **Node.js:** `26.1.0` (with `npm`)
- **Yarn:** `1.22.x`
- **PostgreSQL:** Running locally with a superuser role matching your current system user with database creation permissions (postgress needs the same user as the os user)

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
5. **Set up and seed the database:**
   `bin/rails db:prepare`
6. **Build CSS:**
   `npm run build:css`
7. **Start the development server:**
   `bin/dev`