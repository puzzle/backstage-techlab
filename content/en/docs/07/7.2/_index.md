---
title: "7.2 Backend Plugin"
weight: 72
sectionnumber: 7.2
---

In this section, you'll create a backend plugin that provides a REST API for managing todos. It uses the **new Backend System** with `createBackendPlugin` and stores data in a SQLite database (via Knex).


## Task {{% param sectionnumber %}}.1: Scaffold the Backend Plugin

Use the Backstage CLI to create a new backend plugin:

```bash
# From your Backstage root directory
yarn new
```

When prompted:

* Select **`backend-plugin`**
* Enter the plugin ID: **`todo`**

This creates a new package at `plugins/todo-backend/`.


### Plugin Anatomy

A Backstage backend plugin is a standalone **package** that lives inside the `plugins/` directory, following the convention of appending `-backend` to the plugin name. It is managed by Yarn workspaces and follows this structure:

```text
plugins/todo-backend/
├── package.json          # Plugin metadata, scripts, and dependencies
├── src/
│   ├── index.ts          # Public entry point (default export = plugin)
│   ├── plugin.ts         # Plugin definition (services, router registration)
│   ├── router.ts         # Express router with REST endpoints
│   └── database.ts       # Database layer (Knex queries, migrations)
```


### How it lives in the repo

* Like frontend plugins, the backend plugin is a **workspace package** with its own `package.json`, linked into the monorepo via Yarn workspaces.
* It is referenced by its package name (e.g. `@internal/backstage-plugin-todo-backend`).
* Unlike frontend plugins, backend plugins are **not auto-discovered**. They are registered in `packages/backend/src/index.ts` using `backend.add(import(...))`.


### Key dependencies

| Package | Purpose |
| --------- | --------- |
| `@backstage/backend-plugin-api` | Core APIs for defining backend plugins, accessing services (`coreServices`), and registering routes |
| `express` | HTTP framework — each backend plugin exposes an Express `Router` |
| `knex` | SQL query builder — provided by Backstage's built-in database service, used for queries and migrations |

Dependencies are declared in the plugin's own `package.json`. Backstage's backend framework injects shared services (database, logger, HTTP router, auth) automatically.


### How the plugin integrates with the app

The plugin exports a **default export** created with `createBackendPlugin`. This export declares:

* **Service dependencies** — which core services (database, logger, HTTP router) the plugin needs, declared via `coreServices.*`.
* **Initialization logic** — an `init` function that sets up the database, creates the Express router, and registers it with the HTTP router service.

The backend mounts the plugin's routes under `/api/<pluginId>/` (e.g. `/api/todo/`). The /api/ prefix is a Backstage convention for all backend plugin APIs. The `pluginId` in `createBackendPlugin` determines this path segment.


## Task {{% param sectionnumber %}}.2: Define the Database Layer

The database layer handles all SQL interactions using Knex (which comes built-in with Backstage's database service).

Create `plugins/todo-backend/src/database.ts`:

```typescript
import { Knex } from 'knex';
import { v4 as uuid } from 'uuid';

export interface TodoRow {
  id: string;
  title: string;
  entity_ref: string | null;
  created_at: string;
  completed: number; // SQLite uses 0/1 for booleans
}

export interface TodoInput {
  title: string;
  entityRef?: string;
}

export interface TodoUpdate {
  title?: string;
  completed?: boolean;
}

export interface TodoItem {
  id: string;
  title: string;
  entityRef?: string;
  createdAt: string;
  completed: boolean;
}

export class TodoDatabase {
  constructor(private readonly db: Knex) {}

  static async create(knex: Knex): Promise<TodoDatabase> {
    await TodoDatabase.runMigrations(knex);
    return new TodoDatabase(knex);
  }

  private static async runMigrations(knex: Knex): Promise<void> {
    const hasTable = await knex.schema.hasTable('todos');
    if (!hasTable) {
      await knex.schema.createTable('todos', (table) => {
        table.string('id').primary();
        table.string('title').notNullable();
        table.string('entity_ref').nullable();
        table.string('created_at').notNullable();
        table.integer('completed').notNullable().defaultTo(0);
      });
    }
  }

  private rowToItem(row: TodoRow): TodoItem {
    return {
      id: row.id,
      title: row.title,
      entityRef: row.entity_ref ?? undefined,
      createdAt: row.created_at,
      completed: row.completed === 1,
    };
  }

  async getAll(entityRef?: string): Promise<TodoItem[]> {
    let query = this.db<TodoRow>('todos').orderBy('created_at', 'desc');
    if (entityRef) {
      query = query.where('entity_ref', entityRef);
    }
    const rows = await query;
    return rows.map(row => this.rowToItem(row));
  }

  async getById(id: string): Promise<TodoItem | undefined> {
    const row = await this.db<TodoRow>('todos').where('id', id).first();
    return row ? this.rowToItem(row) : undefined;
  }

  async create(input: TodoInput): Promise<TodoItem> {
    const row: TodoRow = {
      id: uuid(),
      title: input.title,
      entity_ref: input.entityRef ?? null,
      created_at: new Date().toISOString(),
      completed: 0,
    };
    await this.db<TodoRow>('todos').insert(row);
    return this.rowToItem(row);
  }

  async update(id: string, updates: TodoUpdate): Promise<TodoItem> {
    const existing = await this.db<TodoRow>('todos').where('id', id).first();
    if (!existing) {
      throw new Error(`Todo with id ${id} not found`);
    }

    const patch: Partial<TodoRow> = {};
    if (updates.title !== undefined) patch.title = updates.title;
    if (updates.completed !== undefined) patch.completed = updates.completed ? 1 : 0;

    await this.db<TodoRow>('todos').where('id', id).update(patch);
    const updated = await this.db<TodoRow>('todos').where('id', id).first();
    return this.rowToItem(updated!);
  }

  async delete(id: string): Promise<void> {
    const count = await this.db<TodoRow>('todos').where('id', id).delete();
    if (count === 0) {
      throw new Error(`Todo with id ${id} not found`);
    }
  }
}
```


### Code Walkthrough

```typescript
export interface TodoRow {
  ...
  completed: number; // SQLite uses 0/1 for booleans
}
```

**`TodoRow` vs `TodoItem`** — Two separate interfaces exist because the database representation differs from the API representation. SQLite has no native boolean type, so `completed` is stored as `0`/`1` (integer).

**`entity_ref` vs `entityRef`** — The database columns use `snake_case` (SQL convention), while the TypeScript API uses `camelCase` (JS convention). The mapping between these is handled explicitly in `rowToItem` and when building insert rows.


```typescript
private static async runMigrations(knex: Knex): Promise<void> {
  const hasTable = await knex.schema.hasTable('todos');
  if (!hasTable) {
    await knex.schema.createTable('todos', (table) => { ... });
  }
}
```

**Inline migrations** — This is a simplified migration strategy that checks if the table exists and creates it if not. For production plugins with evolving schemas, you'd use Knex's proper migration framework with versioned migration files.

```typescript
async getAll(entityRef?: string): Promise<TodoItem[]> {
  let query = this.db<TodoRow>('todos').orderBy('created_at', 'desc');
  if (entityRef) {
    query = query.where('entity_ref', entityRef);
  }
  const rows = await query;
  return rows.map(row => this.rowToItem(row));
}
```

**Knex query building** — Knex uses a chainable API to build SQL queries. `this.db<TodoRow>('todos')` starts a query on the `todos` table with type safety. The generic `<TodoRow>` tells TypeScript what shape the rows will have.


## Task {{% param sectionnumber %}}.3: Create the Express Router

The router exposes RESTful endpoints for the Todo CRUD operations.

Update `plugins/todo-backend/src/router.ts` to:

```typescript
import express, { Router } from 'express';
import { TodoDatabase } from './database';
import { LoggerService } from '@backstage/backend-plugin-api';

export interface RouterOptions {
  database: TodoDatabase;
  logger: LoggerService;
}

export async function createRouter(options: RouterOptions): Promise<Router> {
  const { database, logger } = options;
  const router = Router();
  router.use(express.json());

  // GET /todos?entityRef=component:default/my-service
  router.get('/todos', async (req, res) => {
    const entityRef = req.query.entityRef as string | undefined;
    logger.debug(`Fetching todos${entityRef ? ` for ${entityRef}` : ''}`);
    const todos = await database.getAll(entityRef);
    res.json(todos);
  });

  // GET /todos/:id
  router.get('/todos/:id', async (req, res) => {
    const todo = await database.getById(req.params.id);
    if (!todo) {
      res.status(404).json({ error: 'Todo not found' });
      return;
    }
    res.json(todo);
  });

  // POST /todos
  router.post('/todos', async (req, res) => {
    const { title, entityRef } = req.body;
    if (!title) {
      res.status(400).json({ error: 'title is required' });
      return;
    }
    logger.info(`Creating todo: "${title}"${entityRef ? ` for ${entityRef}` : ''}`);
    const todo = await database.create({ title, entityRef });
    res.status(201).json(todo);
  });

  // PATCH /todos/:id
  router.patch('/todos/:id', async (req, res) => {
    const { title, completed } = req.body;
    try {
      const todo = await database.update(req.params.id, { title, completed });
      res.json(todo);
    } catch (error: any) {
      if (error.message?.includes('not found')) {
        res.status(404).json({ error: error.message });
      } else {
        throw error;
      }
    }
  });

  // DELETE /todos/:id
  router.delete('/todos/:id', async (req, res) => {
    try {
      await database.delete(req.params.id);
      res.status(204).send();
    } catch (error: any) {
      if (error.message?.includes('not found')) {
        res.status(404).json({ error: error.message });
      } else {
        throw error;
      }
    }
  });

  return router;
}
```


### Code Walkthrough

```typescript
import express, { Router } from 'express';
...
const router = Router();
router.use(express.json());
```

**`express.json()` middleware** — This must be added explicitly to parse JSON request bodies. Backstage's `httpRouter` service does not add body-parsing middleware automatically.

```typescript
export interface RouterOptions {
  database: TodoDatabase;
  logger: LoggerService;
}
```

**Dependency injection via options** — The router receives its dependencies (database, logger) as constructor options rather than importing them globally. This makes the router testable — in tests you can pass a mock database and logger without touching real infrastructure.


## Task {{% param sectionnumber %}}.4: Create the Backend Plugin

Now wire the router and database into a proper backend plugin using the new Backend System.

Replace the content of `plugins/todo-backend/src/plugin.ts`:

```typescript
import {
  coreServices,
  createBackendPlugin,
} from '@backstage/backend-plugin-api';
import { createRouter } from './router';
import { TodoDatabase } from './database';

export const todoPlugin = createBackendPlugin({
  pluginId: 'todo',
  register(env) {
    env.registerInit({
      deps: {
        httpRouter: coreServices.httpRouter,
        database: coreServices.database,
        logger: coreServices.logger,
      },
      async init({ httpRouter, database, logger }) {
        const knex = await database.getClient();
        const todoDb = await TodoDatabase.create(knex);
        const router = await createRouter({ database: todoDb, logger });

        httpRouter.use(router);
        httpRouter.addAuthPolicy({
          path: '/',
          allow: 'unauthenticated',
        });
      },
    });
  },
});
```


### Code Walkthrough

```typescript
export const todoPlugin = createBackendPlugin({
  pluginId: 'todo',
  register(env) {
    env.registerInit({ ... });
  },
});
```

**`createBackendPlugin`** — The top-level factory for backend plugins. The `pluginId` determines both the API route prefix (`/api/todo/`) and the database namespace. The `register` function is called once during app startup.

**`env.registerInit`** — Registers the plugin's initialization logic. This is where you declare dependencies and provide the `init` function. The backend framework calls `init` once all declared dependencies are resolved and ready.

```typescript
deps: {
  httpRouter: coreServices.httpRouter,
  database: coreServices.database,
  logger: coreServices.logger,
},
async init({ httpRouter, database, logger }) { ... }
```

**`coreServices.*`** — These are service references (similar to `createApiRef` in the frontend). They declare *what* the plugin needs, and the backend framework injects the actual implementations. Available core services include `httpRouter`, `database`, `logger`, `auth`, `config`, `permissions`, and more.


```typescript
httpRouter.addAuthPolicy({
  path: '/',
  allow: 'unauthenticated',
});
```

**`addAuthPolicy`** — Backstage's backend requires explicit auth policies for all routes. Without a policy, requests are rejected by the auth middleware (resulting in 404). Setting `path: '/'` with `allow: 'unauthenticated'` opens all routes under this plugin for unauthenticated access — suitable for local development but not production.


## Task {{% param sectionnumber %}}.5: Export the Plugin

Check `plugins/todo-backend/src/index.ts` to contain:

```typescript
export { todoPlugin as default } from './plugin';
```


## Task {{% param sectionnumber %}}.6: Install Dependencies

The backend plugin needs `uuid` for generating unique IDs:

```bash
# From your Backstage root directory
yarn --cwd plugins/todo-backend add uuid
yarn --cwd plugins/todo-backend add --dev @types/uuid
```


## Task {{% param sectionnumber %}}.7: Register in the Backend

The todo backend plugin is automatically registered through the plugin cli:

In `packages/backend/src/index.ts`
```typescript
backend.add(import('@internal/backstage-plugin-todo-backend'));
```

In `packages/backend/package.json`
```json
{
  "dependencies": {
    "@internal/backstage-plugin-todo-backend": "workspace:^",
  }
}
```


## Task {{% param sectionnumber %}}.8: Verify the Backend

Test the functionality of the backend using it's API.

{{% alert title="Note" color="primary" %}}
The frontend plugin is not jet connected to the new backend plugin.

Data is not exchanged. This will be set up in the nex lab.
{{% /alert %}}


Start the application:

```bash
yarn start
```

Test the API with curl:

```bash
# Create a todo
curl -X POST http://localhost:7007/api/todo/todos \
  -H "Content-Type: application/json" \
  -d '{"title": "My first todo", "entityRef": "component:default/my-sample-service"}'

# List all todos
curl http://localhost:7007/api/todo/todos

# List todos for a specific entity
curl "http://localhost:7007/api/todo/todos?entityRef=component:default/my-sample-service"
```

You should see JSON responses with the created todo items.

{{% alert title="Note" color="primary" %}}
The backend API is available under `/api/todo/` — the `todo` path segment comes from the `pluginId` defined in `createBackendPlugin`.
{{% /alert %}}


## Task {{% param sectionnumber %}}.9: Database Storage

By default, Backstage uses a **SQLite** database in development mode. The data is stored in memory. You can keep this like it is, but the data is lost after each restart.
Otherwise, change the connection string to store the database in a file at the project root. You can check the database configuration in `app-config.yaml`:


```yaml
backend:
  database:
    client: better-sqlite3
    connection:
      directory: './db'
```


## Summary

In this section, you:

* ✅ Created a backend plugin using the new Backend System
* ✅ Implemented a database layer with Knex migrations
* ✅ Built a REST API with CRUD endpoints
* ✅ Registered the plugin in the backend
* ✅ Verified the API works with curl

The backend is now running and ready to serve data. In the next section, we'll connect the frontend to this backend and add tests.
