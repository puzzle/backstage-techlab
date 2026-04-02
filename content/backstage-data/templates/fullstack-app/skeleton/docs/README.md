# ${{ values.name }} Documentation

## Overview

${{ values.description }}

## Getting Started

### Prerequisites

- Node.js 18 or higher
- Docker and Docker Compose
{% if values.database == 'postgresql' %}- PostgreSQL{% endif %}
{% if values.database == 'mysql' %}- MySQL{% endif %}
{% if values.database == 'mongodb' %}- MongoDB{% endif %}

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   npm install
   ```

3. Start the development environment:
   ```bash
   docker-compose up -d
   ```

4. Run the application:
   ```bash
   npm run dev
   ```

## Architecture

This is a full-stack application with:
- **Frontend**: React with Vite
- **Backend**: Node.js/Express
- **Database**: ${{ values.database }}

## Development

### Running Locally

```bash
npm run dev
```

### Running Tests

```bash
npm test
```

### Building for Production

```bash
npm run build
```

## Deployment

The application is configured with GitHub Actions for CI/CD. Every push to the main branch will trigger automated tests and builds.

## Owner

Maintained by: ${{ values.owner }}
