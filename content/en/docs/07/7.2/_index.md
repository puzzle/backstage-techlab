---
title: "7.2 Backend Plugin"
weight: 72
sectionnumber: 7.2
---

In this section, you'll create a backend plugin that provides a REST API for managing todos. It uses the **new Backend System** with `createBackendPlugin` and stores data in a SQLite database (via Knex).


## Task {{% param sectionnumber %}}.1: Scaffold the Backend Plugin

Use the Backstage CLI to create a new backend plugin:

```bash
cd my-backstage-app
yarn new
```

When prompted:
- Select **`backend-plugin`**
- Enter the plugin ID: **`todo`**

This creates a new package at `plugins/todo-backend/`.


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


## Task {{% param sectionnumber %}}.3: Create the Express Router

The router exposes RESTful endpoints for the Todo CRUD operations.

Create `plugins/todo-backend/src/router.ts`:

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

{{% alert title="Note" color="primary" %}}
The `httpRouter.addAuthPolicy` with `allow: 'unauthenticated'` is used here for simplicity in local development. In a production setup, you should configure proper authentication policies.
{{% /alert %}}


## Task {{% param sectionnumber %}}.5: Export the Plugin

Update `plugins/todo-backend/src/index.ts`:

```typescript
export { todoPlugin as default } from './plugin';
```


## Task {{% param sectionnumber %}}.6: Install Dependencies

The backend plugin needs `uuid` for generating unique IDs:

```bash
yarn --cwd plugins/todo-backend add uuid
yarn --cwd plugins/todo-backend add --dev @types/uuid
```


## Task {{% param sectionnumber %}}.7: Register in the Backend

Add the todo backend plugin to `packages/backend/src/index.ts`:

```typescript
// Add this line alongside the other backend.add() calls
backend.add(import('../../../plugins/todo-backend/src'));
```

Alternatively, if your backend uses package discovery (similar to the frontend), the plugin will be auto-discovered. Check if your backend `index.ts` already has a wildcard import pattern.

{{% alert title="Note" color="primary" %}}
The path may vary depending on your project structure. If using workspace references, you can also add the plugin as a dependency in `packages/backend/package.json`:

```json
{
  "dependencies": {
    "plugin-todo-backend": "link:../../plugins/todo-backend"
  }
}
```

And then import it:
```typescript
backend.add(import('plugin-todo-backend'));
```
{{% /alert %}}


## Task {{% param sectionnumber %}}.8: Verify the Backend

Start the application:

```bash
yarn start
```

Test the API with curl:

```bash
# Create a todo
curl -X POST http://localhost:7007/api/todo/todos \
  -H "Content-Type: application/json" \
  -d '{"title": "My first todo", "entityRef": "component:default/my-service"}'

# List all todos
curl http://localhost:7007/api/todo/todos

# List todos for a specific entity
curl "http://localhost:7007/api/todo/todos?entityRef=component:default/my-service"
```

You should see JSON responses with the created todo items.

{{% alert title="Note" color="primary" %}}
The backend API is available under `/api/todo/` — the `todo` path segment comes from the `pluginId` defined in `createBackendPlugin`.
{{% /alert %}}


## Task {{% param sectionnumber %}}.9: Database Storage

By default, Backstage uses a **SQLite** database in development mode. The data is stored in a file at the project root. You can check the database configuration in `app-config.yaml`:

```yaml
backend:
  database:
    client: better-sqlite3
    connection: ':memory:'
```


## Summary

In this section, you:

* ✅ Created a backend plugin using the new Backend System
* ✅ Implemented a database layer with Knex migrations
* ✅ Built a REST API with CRUD endpoints
* ✅ Registered the plugin in the backend
* ✅ Verified the API works with curl

The backend is now running and ready to serve data. In the next section, we'll connect the frontend to this backend and add tests.
