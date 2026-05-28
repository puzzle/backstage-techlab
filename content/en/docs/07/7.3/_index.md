---
title: "7.3 API Integration and Testing"
weight: 73
sectionnumber: 7.3
---

In this section, you'll connect the frontend plugin to the backend API and write tests for both parts. After this, your Todo plugin will be fully functional with persistent storage.


## Task {{% param sectionnumber %}}.1: Create the Backend API Client

Replace the `LocalStorageTodoApi` with a proper client that calls the backend. We'll keep both implementations so you can switch between them.

Create `plugins/todo/src/api.client.ts`:

```typescript
import { DiscoveryApi, FetchApi } from '@backstage/frontend-plugin-api';
import { Todo, TodoApi } from './types';

export class BackendTodoApi implements TodoApi {
  constructor(
    private readonly discoveryApi: DiscoveryApi,
    private readonly fetchApi: FetchApi,
  ) {}

  private async getBaseUrl(): Promise<string> {
    return `${await this.discoveryApi.getBaseUrl('todo')}/todos`;
  }

  async getTodos(options?: { entityRef?: string }): Promise<Todo[]> {
    const baseUrl = await this.getBaseUrl();
    const params = new URLSearchParams();
    if (options?.entityRef) {
      params.set('entityRef', options.entityRef);
    }
    const url = params.toString() ? `${baseUrl}?${params}` : baseUrl;
    const response = await this.fetchApi.fetch(url);
    if (!response.ok) {
      throw new Error(`Failed to fetch todos: ${response.statusText}`);
    }
    return response.json();
  }

  async createTodo(input: { title: string; entityRef?: string }): Promise<Todo> {
    const baseUrl = await this.getBaseUrl();
    const response = await this.fetchApi.fetch(baseUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(input),
    });
    if (!response.ok) {
      throw new Error(`Failed to create todo: ${response.statusText}`);
    }
    return response.json();
  }

  async updateTodo(
    id: string,
    updates: Partial<Pick<Todo, 'title' | 'completed'>>,
  ): Promise<Todo> {
    const baseUrl = await this.getBaseUrl();
    const response = await this.fetchApi.fetch(`${baseUrl}/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(updates),
    });
    if (!response.ok) {
      throw new Error(`Failed to update todo: ${response.statusText}`);
    }
    return response.json();
  }

  async deleteTodo(id: string): Promise<void> {
    const baseUrl = await this.getBaseUrl();
    const response = await this.fetchApi.fetch(`${baseUrl}/${id}`, {
      method: 'DELETE',
    });
    if (!response.ok) {
      throw new Error(`Failed to delete todo: ${response.statusText}`);
    }
  }
}
```


## Task {{% param sectionnumber %}}.2: Update the Plugin to Use the Backend Client

Now update `plugins/todo/src/plugin.ts` to use the `BackendTodoApi` instead of the localStorage implementation:

```typescript
import {
  createFrontendPlugin,
  PageBlueprint,
  ApiBlueprint,
  discoveryApiRef,
  fetchApiRef,
} from '@backstage/frontend-plugin-api';
import { EntityCardBlueprint } from '@backstage/plugin-catalog-react/alpha';
import { rootRouteRef } from './routes';
import { todoApiRef } from './api';
import { BackendTodoApi } from './api.client';

const todoApi = ApiBlueprint.make({
  name: 'todo',
  params: defineParams =>
    defineParams({
      api: todoApiRef,
      deps: {
        discoveryApi: discoveryApiRef,
        fetchApi: fetchApiRef,
      },
      factory: ({ discoveryApi, fetchApi }) =>
        new BackendTodoApi(discoveryApi, fetchApi),
    }),
});

const todoPage = PageBlueprint.make({
  params: {
    routeRef: rootRouteRef,
    path: '/todo',
    title: 'Todo',
    loader: () => import('./components/TodoPage').then(m => <m.TodoPage />),
  },
});

const entityTodoCard = EntityCardBlueprint.make({
  name: 'todo',
  params: {
    filter: 'kind:component,api,resource,system',
    loader: () =>
      import('./components/EntityTodoCard').then(m => <m.EntityTodoCard />),
  },
});

export const todoPlugin = createFrontendPlugin({
  pluginId: 'todo',
  extensions: [todoApi, todoPage, entityTodoCard],
  routes: {
    root: rootRouteRef,
  },
});
```

{{% alert title="Note" color="primary" %}}
The `discoveryApiRef` resolves the backend base URL for the `todo` plugin (i.e., `http://localhost:7007/api/todo`). The `fetchApiRef` provides an authenticated fetch function that automatically includes the user's credentials.
{{% /alert %}}


## Task {{% param sectionnumber %}}.3: Verify End-to-End

Start the full application:

```bash
yarn start
```

Now test the complete flow:

1. Navigate to `/todo` and create a few todos
2. Restart the application — your todos should **persist** (if using file-based SQLite)
3. Open any component in the catalog
4. The Entity Todo Card should show and allow managing todos specific to that entity
5. Todos created on the entity page should also appear in the main `/todo` page with the entity reference


## Task {{% param sectionnumber %}}.4: Test the Backend Plugin

Create `plugins/todo-backend/src/router.test.ts`:

```typescript
import express from 'express';
import request from 'supertest';
import { createRouter } from './router';
import { TodoDatabase } from './database';
import { getVoidLogger } from '@backstage/backend-test-utils';
import Knex from 'knex';

describe('todo router', () => {
  let app: express.Express;
  let database: TodoDatabase;

  beforeAll(async () => {
    const knex = Knex({
      client: 'better-sqlite3',
      connection: ':memory:',
      useNullAsDefault: true,
    });

    database = await TodoDatabase.create(knex);
    const router = await createRouter({
      database,
      logger: getVoidLogger(),
    });

    app = express();
    app.use(express.json());
    app.use(router);
  });

  it('should create a todo', async () => {
    const response = await request(app)
      .post('/todos')
      .send({ title: 'Test todo', entityRef: 'component:default/test' })
      .expect(201);

    expect(response.body).toMatchObject({
      title: 'Test todo',
      entityRef: 'component:default/test',
      completed: false,
    });
    expect(response.body.id).toBeDefined();
  });

  it('should list todos', async () => {
    const response = await request(app)
      .get('/todos')
      .expect(200);

    expect(response.body.length).toBeGreaterThan(0);
  });

  it('should filter todos by entityRef', async () => {
    await request(app)
      .post('/todos')
      .send({ title: 'Other entity todo', entityRef: 'component:default/other' });

    const response = await request(app)
      .get('/todos?entityRef=component:default/test')
      .expect(200);

    expect(response.body.every((t: any) => t.entityRef === 'component:default/test')).toBe(true);
  });

  it('should update a todo', async () => {
    const createRes = await request(app)
      .post('/todos')
      .send({ title: 'To be updated' });

    const response = await request(app)
      .patch(`/todos/${createRes.body.id}`)
      .send({ completed: true })
      .expect(200);

    expect(response.body.completed).toBe(true);
  });

  it('should delete a todo', async () => {
    const createRes = await request(app)
      .post('/todos')
      .send({ title: 'To be deleted' });

    await request(app)
      .delete(`/todos/${createRes.body.id}`)
      .expect(204);

    await request(app)
      .get(`/todos/${createRes.body.id}`)
      .expect(404);
  });

  it('should return 400 for missing title', async () => {
    await request(app)
      .post('/todos')
      .send({})
      .expect(400);
  });

  it('should return 404 for non-existent todo', async () => {
    await request(app)
      .patch('/todos/non-existent-id')
      .send({ completed: true })
      .expect(404);
  });
});
```

Install the test dependencies:

```bash
yarn --cwd plugins/todo-backend add --dev supertest @types/supertest @backstage/backend-test-utils knex better-sqlite3
```

Run the tests:

```bash
yarn --cwd plugins/todo-backend test
```


## Task {{% param sectionnumber %}}.5: Test the Frontend Components

Create `plugins/todo/src/components/TodoPage.test.tsx`:

```typescript
import React from 'react';
import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { renderInTestApp, TestApiProvider } from '@backstage/frontend-test-utils';
import { TodoPage } from './TodoPage';
import { todoApiRef } from '../api';
import { Todo, TodoApi } from '../types';

const mockTodos: Todo[] = [
  {
    id: '1',
    title: 'Test todo',
    entityRef: 'component:default/test',
    createdAt: new Date().toISOString(),
    completed: false,
  },
];

const mockApi: jest.Mocked<TodoApi> = {
  getTodos: jest.fn().mockResolvedValue(mockTodos),
  createTodo: jest.fn().mockResolvedValue(mockTodos[0]),
  updateTodo: jest.fn().mockResolvedValue({ ...mockTodos[0], completed: true }),
  deleteTodo: jest.fn().mockResolvedValue(undefined),
};

describe('TodoPage', () => {
  it('should render the todo list', async () => {
    await renderInTestApp(
      <TestApiProvider apis={[[todoApiRef, mockApi]]}>
        <TodoPage />
      </TestApiProvider>,
    );

    await waitFor(() => {
      expect(screen.getByText('Test todo')).toBeInTheDocument();
    });
  });

  it('should create a new todo', async () => {
    const user = userEvent.setup();

    await renderInTestApp(
      <TestApiProvider apis={[[todoApiRef, mockApi]]}>
        <TodoPage />
      </TestApiProvider>,
    );

    const input = screen.getByPlaceholderText('What needs to be done?');
    await user.type(input, 'New todo item');
    await user.click(screen.getByText('Add Todo'));

    expect(mockApi.createTodo).toHaveBeenCalledWith({
      title: 'New todo item',
    });
  });
});
```

Install frontend test dependencies:

```bash
yarn --cwd plugins/todo add --dev @testing-library/react @testing-library/user-event @backstage/frontend-test-utils
```

Run the frontend tests:

```bash
yarn --cwd plugins/todo test
```

## Summary

In this section, you:

* ✅ Created a backend API client using `DiscoveryApi` and `FetchApi`
* ✅ Connected the frontend plugin to the backend
* ✅ Wrote comprehensive backend route tests
* ✅ Wrote frontend component tests with mocked APIs
* ✅ Tested the API end-to-end with curl

Your Todo plugin is now fully functional with:
- A standalone page at `/todo` showing all todos
- An entity card on catalog pages showing entity-specific todos
- Persistent storage in the backend database
- Full test coverage for both frontend and backend

