# ${{ values.name }}

${{ values.description }}

## Architecture

This is a full-stack application with:
- **Frontend**: React application with Vite
- **Backend**: Node.js/Express API
- **Database**: ${{ values.database }}
{% if values.includeAuth %}
- **Authentication**: JWT-based authentication
{% endif %}

## Owner

${{ values.owner }}

## Getting Started

### Prerequisites

- Node.js 22+
- ${{ values.database | capitalize }}
- Docker (optional, for containerized development)

### Installation

```bash
npm install
```

### Running Locally

Start both frontend and backend in development mode:

```bash
npm run dev
```

Or run them separately:

```bash
# Frontend (http://localhost:5173)
npm run dev:frontend

# Backend (http://localhost:3001)
npm run dev:backend
```

### Running with Docker

```bash
docker-compose up
```

### Running Tests

```bash
npm test
```

## Project Structure

```
.
├── frontend/          # React frontend application
├── backend/           # Node.js backend API
├── docs/              # Documentation
├── .github/           # GitHub Actions workflows
└── docker-compose.yml # Docker configuration
```

## API Documentation

The API is available at `http://localhost:3001/api`

See the [API Documentation](./docs/api.md) for detailed endpoint information.

## Deployment

This project includes GitHub Actions workflows for CI/CD. Push to the `main` branch to trigger deployment.
