# API Reference

Base URL: `http://localhost:3001/api`

## Health Check

### GET /api/health

Check the health status of the API.

**Response**
```json
{
  "status": "healthy",
  "service": "${{ values.name }}",
  "database": "${{ values.database }}",
  "timestamp": "2024-01-01T12:00:00.000Z"
}
```

**Status Codes**
- `200 OK`: Service is healthy

---

{% if values.includeAuth %}
## Authentication

### POST /api/auth/register

Register a new user account.

**Request Body**
```json
{
  "email": "user@example.com",
  "password": "securePassword123",
  "name": "John Doe"
}
```

**Response**
```json
{
  "message": "User registered successfully",
  "userId": "123"
}
```

**Status Codes**
- `201 Created`: User registered successfully
- `400 Bad Request`: Invalid input data
- `409 Conflict`: User already exists

---

### POST /api/auth/login

Authenticate a user and receive a JWT token.

**Request Body**
```json
{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

**Response**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "123",
    "email": "user@example.com",
    "name": "John Doe"
  }
}
```

**Status Codes**
- `200 OK`: Authentication successful
- `401 Unauthorized`: Invalid credentials

---

### GET /api/auth/me

Get current user information (requires authentication).

**Headers**
```
Authorization: Bearer <token>
```

**Response**
```json
{
  "id": "123",
  "email": "user@example.com",
  "name": "John Doe"
}
```

**Status Codes**
- `200 OK`: User information retrieved
- `401 Unauthorized`: Invalid or missing token

---
{% endif %}

## Error Responses

All endpoints may return the following error format:

```json
{
  "error": "Error message description",
  "code": "ERROR_CODE",
  "details": {}
}
```

**Common Status Codes**
- `400 Bad Request`: Invalid request parameters
- `401 Unauthorized`: Authentication required or failed
- `403 Forbidden`: Insufficient permissions
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server error

## Rate Limiting

Currently no rate limiting is implemented. Consider adding rate limiting for production deployments.

## Authentication

{% if values.includeAuth %}
Most endpoints require authentication via JWT token in the Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

Tokens expire after 7 days by default (configurable via `JWT_EXPIRES_IN` environment variable).
{% else %}
This API currently does not implement authentication. Consider adding authentication for production use.
{% endif %}

## CORS

CORS is enabled for development. Configure allowed origins in production via environment variables.

## Pagination

For endpoints returning lists, pagination will be implemented using:

**Query Parameters**
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 20, max: 100)

**Response Format**
```json
{
  "data": [],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "pages": 5
  }
}
```

## Versioning

API versioning is not currently implemented. Future versions may use URL-based versioning (e.g., `/api/v2/`).
