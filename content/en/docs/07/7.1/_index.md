---
title: "7.1 Frontend Plugin"
weight: 71
sectionnumber: 7.1
---

In this section, you'll create a frontend plugin that provides a Todo list page and an entity card for the catalog. We'll use **localStorage** as a temporary data store so the plugin works standalone without a backend.

## Task {{% param sectionnumber %}}.1: Scaffold the Plugin

Use the Backstage CLI to create a new frontend plugin:

```bash
cd my-backstage-app
yarn new
```

When prompted:
- Select **`frontend-plugin`**
- Enter the plugin ID: **`todo`**

This creates a new package at `plugins/todo/` with a basic plugin structure.

{{% alert title="Note" color="primary" %}}
The `yarn new` scaffolder currently generates plugin code using the **legacy frontend system** (`createPlugin` from `@backstage/core-plugin-api`). This is [expected behavior](https://backstage.io/docs/frontend-system/building-plugins/index/). We will replace `plugin.ts` and `index.ts` with the new frontend system APIs in Task {{% param sectionnumber %}}.7 and {{% param sectionnumber %}}.8.
{{% /alert %}}


### Plugin Anatomy

A Backstage frontend plugin is a standalone **package** that lives inside the `plugins/` directory of your Backstage monorepo. It is managed by the workspace's package manager (Yarn) and follows a conventional structure:

```text
plugins/todo/
├── package.json          # Plugin metadata, scripts, and dependencies
├── src/
│   ├── index.ts          # Public entry point (default export = plugin)
│   ├── plugin.ts         # Plugin definition (extensions, routes, APIs)
│   ├── api.ts            # Utility API reference and implementation
│   ├── routes.ts         # Route references
│   ├── types.ts          # Shared TypeScript interfaces
│   └── components/       # React components
│       └── MyComponent.tsx
└── dev/                  # (optional) Isolated dev setup for standalone dev
```

### How it lives in the repo

- The plugin is a **workspace package** — it has its own `package.json` and is linked into the monorepo via Yarn workspaces. The `backstage-cli` provides additional tooling (scaffolding, building, serving) on top of the standard Yarn workspace setup.
- It is referenced by its package name (e.g. `@internal/backstage-plugin-todo`).
- The app discovers the plugin automatically at build time through the `app.packages: all` setting in `app-config.yaml`, which scans all workspace packages for valid Backstage plugins.

### Key dependencies

| Package | Purpose |
|---------|---------|
| `@backstage/frontend-plugin-api` | Core APIs for defining plugins, extensions, routes, and Utility APIs (new frontend system) |
| `@backstage/core-components` | Reusable UI building blocks (`Header`, `Page`, `Content`, `Table`, etc.) |
| `@backstage/plugin-catalog-react` | Catalog-aware hooks and blueprints (e.g. `useEntity`, `EntityCardBlueprint`) |
| `@backstage/catalog-model` | Entity type definitions and helpers like `stringifyEntityRef` |
| `@material-ui/core` / `@material-ui/icons` | Material UI components used in Backstage's design system |

All of the above are declared as **dependencies** in the plugin's own `package.json`. Backstage's build tooling handles bundling and deduplication across the monorepo.

### How the plugin integrates with the app

The plugin exports a **default export** created with `createFrontendPlugin`. This export declares:

- **Extensions** — the UI pieces (pages, entity cards, API factories) the plugin provides.
- **Routes** — route references that the app can bind to navigation.

The app's feature discovery mechanism picks up the default export and installs all declared extensions. No manual wiring in `App.tsx` is required when using the new frontend system with automatic discovery.





## Task {{% param sectionnumber %}}.2: Define Shared Types

Before building components, let's define the data types for our Todo items.

Create the file `plugins/todo/src/types.ts`:

```typescript
export interface Todo {
  id: string;
  title: string;
  entityRef?: string;
  createdAt: string;
  completed: boolean;
}

export interface TodoApi {
  getTodos(options?: { entityRef?: string }): Promise<Todo[]>;
  createTodo(todo: { title: string; entityRef?: string }): Promise<Todo>;
  updateTodo(id: string, updates: Partial<Pick<Todo, 'title' | 'completed'>>): Promise<Todo>;
  deleteTodo(id: string): Promise<void>;
}
```

### Code Walkthrough

```typescript
export interface TodoApi {
  ...
  updateTodo(id: string, updates: Partial<Pick<Todo, 'title' | 'completed'>>): Promise<Todo>;
  ...
}
```

**`Partial<Pick<Todo, 'title' | 'completed'>>`** — This TypeScript utility type combination means: pick only the `title` and `completed` fields from `Todo`, then make them all optional. This gives the caller flexibility to update one or both fields without requiring the full object. It's a common pattern for PATCH-style update operations.

**`entityRef?: string`** — The optional `entityRef` field links a todo to a specific catalog entity (e.g. `component:default/my-service`). This allows filtering todos per entity when displaying the Entity Card.

**Why an interface for the API?** — Defining `TodoApi` as an interface (not a class) enables the dependency injection pattern. The interface acts as a contract — any class implementing it can be swapped in via the `ApiBlueprint`. We start with `LocalStorageTodoApi` and later replace it with a backend HTTP client, without changing any component code.


## Task {{% param sectionnumber %}}.3: Create the API Client

We'll create a Utility API that initially uses localStorage. Later in Part 2, we'll swap this with a real backend client.

Create `plugins/todo/src/api.ts`:

```typescript
import { createApiRef } from '@backstage/frontend-plugin-api';
import { Todo, TodoApi } from './types';

export const todoApiRef = createApiRef<TodoApi>({
  id: 'plugin.todo.api',
});

const STORAGE_KEY = 'backstage-todo-items';

export class LocalStorageTodoApi implements TodoApi {
  private getTodosFromStorage(): Todo[] {
    const stored = localStorage.getItem(STORAGE_KEY);
    return stored ? JSON.parse(stored) : [];
  }

  private saveTodosToStorage(todos: Todo[]): void {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(todos));
  }

  async getTodos(options?: { entityRef?: string }): Promise<Todo[]> {
    const todos = this.getTodosFromStorage();
    if (options?.entityRef) {
      return todos.filter(t => t.entityRef === options.entityRef);
    }
    return todos;
  }

  async createTodo(input: { title: string; entityRef?: string }): Promise<Todo> {
    const todos = this.getTodosFromStorage();
    const newTodo: Todo = {
      id: crypto.randomUUID(),
      title: input.title,
      entityRef: input.entityRef,
      createdAt: new Date().toISOString(),
      completed: false,
    };
    todos.push(newTodo);
    this.saveTodosToStorage(todos);
    return newTodo;
  }

  async updateTodo(id: string, updates: Partial<Pick<Todo, 'title' | 'completed'>>): Promise<Todo> {
    const todos = this.getTodosFromStorage();
    const index = todos.findIndex(t => t.id === id);
    if (index === -1) throw new Error(`Todo ${id} not found`);
    todos[index] = { ...todos[index], ...updates };
    this.saveTodosToStorage(todos);
    return todos[index];
  }

  async deleteTodo(id: string): Promise<void> {
    const todos = this.getTodosFromStorage();
    this.saveTodosToStorage(todos.filter(t => t.id !== id));
  }
}
```

### Code Walkthrough

```typescript
export const todoApiRef = createApiRef<TodoApi>({
  id: 'plugin.todo.api',
});
```

**`createApiRef`** — This creates a typed **API reference** — a unique token that the dependency injection system uses to look up the correct implementation at runtime. The generic `<TodoApi>` ensures type safety: when you call `useApi(todoApiRef)`, TypeScript knows the returned object satisfies the `TodoApi` interface. The `id` string must be globally unique across all plugins.

```typescript
export class LocalStorageTodoApi implements TodoApi {
  ...
  async createTodo(input: { title: string; entityRef?: string }): Promise<Todo> {
    ...
    id: crypto.randomUUID(),
    ...
  }
  ...
}
```

**`async` methods returning `Promise`** — Even though localStorage is synchronous, the methods are `async` and return Promises. This is intentional: it matches the `TodoApi` interface contract, which is designed for a real backend (HTTP calls are async). By making the localStorage version async too, we can later swap in the backend client without changing any calling code.

**`crypto.randomUUID()`** — Generates a cryptographically random UUID (v4) for each new todo. This is a browser-native API (no library needed) and ensures unique IDs even across sessions.

**`implements TodoApi`** — The class explicitly implements the interface defined in `types.ts`. TypeScript will produce a compile error if any method is missing or has wrong types, ensuring our implementation stays in sync with the contract.


## Task {{% param sectionnumber %}}.4: Build the Todo Page Component

Create the main Todo page that displays all todos and allows creating new ones.

Create `plugins/todo/src/components/TodoPage.tsx`:

```typescript
import React, { useCallback, useEffect, useState } from 'react';
import {
  Content,
  Header,
  Page,
  Table,
  TableColumn,
} from '@backstage/core-components';
import { useApi } from '@backstage/frontend-plugin-api';
import {
  Button,
  Checkbox,
  IconButton,
  TextField,
  Grid,
  Paper,
  Typography,
} from '@material-ui/core';
import DeleteIcon from '@material-ui/icons/Delete';
import { todoApiRef } from '../api';
import { Todo } from '../types';

export const TodoPage = () => {
  const todoApi = useApi(todoApiRef);
  const [todos, setTodos] = useState<Todo[]>([]);
  const [newTitle, setNewTitle] = useState('');
  const [loading, setLoading] = useState(true);

  const loadTodos = useCallback(async () => {
    setLoading(true);
    const items = await todoApi.getTodos();
    setTodos(items);
    setLoading(false);
  }, [todoApi]);

  useEffect(() => {
    loadTodos();
  }, [loadTodos]);

  const handleCreate = async () => {
    if (!newTitle.trim()) return;
    await todoApi.createTodo({ title: newTitle.trim() });
    setNewTitle('');
    await loadTodos();
  };

  const handleToggle = async (todo: Todo) => {
    await todoApi.updateTodo(todo.id, { completed: !todo.completed });
    await loadTodos();
  };

  const handleDelete = async (id: string) => {
    await todoApi.deleteTodo(id);
    await loadTodos();
  };

  const columns: TableColumn<Todo>[] = [
    {
      title: 'Done',
      field: 'completed',
      width: '5%',
      render: (row) => (
        <Checkbox
          checked={row.completed}
          onChange={() => handleToggle(row)}
        />
      ),
    },
    {
      title: 'Title',
      field: 'title',
      render: (row) => (
        <Typography
          style={{
            textDecoration: row.completed ? 'line-through' : 'none',
            opacity: row.completed ? 0.6 : 1,
          }}
        >
          {row.title}
        </Typography>
      ),
    },
    {
      title: 'Entity',
      field: 'entityRef',
      render: (row) => row.entityRef || '—',
    },
    {
      title: 'Created',
      field: 'createdAt',
      render: (row) => new Date(row.createdAt).toLocaleDateString(),
    },
    {
      title: 'Actions',
      width: '10%',
      render: (row) => (
        <IconButton size="small" onClick={() => handleDelete(row.id)}>
          <DeleteIcon />
        </IconButton>
      ),
    },
  ];

  return (
    <Page themeId="tool">
      <Header title="Todo List" subtitle="Manage your tasks" />
      <Content>
        <Grid container spacing={3}>
          <Grid item xs={12}>
            <Paper style={{ padding: 16 }}>
              <Grid container spacing={2} alignItems="center">
                <Grid item xs>
                  <TextField
                    fullWidth
                    variant="outlined"
                    size="small"
                    placeholder="What needs to be done?"
                    value={newTitle}
                    onChange={(e) => setNewTitle(e.target.value)}
                    onKeyDown={(e) => e.key === 'Enter' && handleCreate()}
                  />
                </Grid>
                <Grid item>
                  <Button
                    variant="contained"
                    color="primary"
                    onClick={handleCreate}
                    disabled={!newTitle.trim()}
                  >
                    Add Todo
                  </Button>
                </Grid>
              </Grid>
            </Paper>
          </Grid>
          <Grid item xs={12}>
            <Table
              title="All Todos"
              columns={columns}
              data={todos}
              isLoading={loading}
              options={{ paging: false, search: true }}
            />
          </Grid>
        </Grid>
      </Content>
    </Page>
  );
};
```

### Code Walkthrough

Let's break down some of the less obvious patterns in this component:

```typescript
...
export const TodoPage = () => {
  const todoApi = useApi(todoApiRef);
...
```

**`useApi(todoApiRef)`** — This is how Backstage's dependency injection works in the frontend. Instead of importing and instantiating the API client directly, you request it through `useApi` using an API reference (`todoApiRef`). The actual implementation is provided by the plugin's `ApiBlueprint` and can be swapped without changing any component code.

```typescript
...
<Page themeId="tool">
      <Header title="Todo List" subtitle="Manage your tasks" />
      <Content>
...
```
**`Page`, `Header`, `Content`** — These are Backstage layout primitives from `@backstage/core-components`. Every top-level plugin page should follow this structure to ensure a consistent look across all plugins.

**`themeId="tool"`** — The `themeId` prop on `Page` controls the **header color gradient**. Backstage ships with several built-in theme IDs (`tool`, `service`, `website`, `library`, `app`, `home`, etc.) that each produce a different color scheme. 

```typescript
...
  const loadTodos = useCallback(async () => {
    setLoading(true);
    const items = await todoApi.getTodos();
    setTodos(items);
    setLoading(false);
  }, [todoApi]);

  useEffect(() => {
    loadTodos();
  }, [loadTodos]);
...
```  

**`useCallback` + `useEffect`** — The `loadTodos` function is wrapped in `useCallback` to create a stable reference that only changes when `todoApi` changes. This prevents `useEffect` from re-running on every render. Without `useCallback`, the effect would trigger an infinite loop: render → new function reference → effect runs → state update → re-render → new function reference → ...



## Task {{% param sectionnumber %}}.5: Build the Entity Todo Card

This component shows todos specific to a catalog entity. It will appear on entity pages.

Create `plugins/todo/src/components/EntityTodoCard.tsx`:

```typescript
import React, { useCallback, useEffect, useState } from 'react';
import { useApi } from '@backstage/frontend-plugin-api';
import { useEntity } from '@backstage/plugin-catalog-react';
import { stringifyEntityRef } from '@backstage/catalog-model';
import {
  Button,
  Card,
  CardContent,
  CardHeader,
  Checkbox,
  IconButton,
  List,
  ListItem,
  ListItemIcon,
  ListItemSecondaryAction,
  ListItemText,
  TextField,
  Grid,
  Typography,
} from '@material-ui/core';
import DeleteIcon from '@material-ui/icons/Delete';
import { todoApiRef } from '../api';
import { Todo } from '../types';

export const EntityTodoCard = () => {
  const { entity } = useEntity();
  const todoApi = useApi(todoApiRef);
  const [todos, setTodos] = useState<Todo[]>([]);
  const [newTitle, setNewTitle] = useState('');

  const entityRef = stringifyEntityRef(entity);

  const loadTodos = useCallback(async () => {
    const items = await todoApi.getTodos({ entityRef });
    setTodos(items);
  }, [todoApi, entityRef]);

  useEffect(() => {
    loadTodos();
  }, [loadTodos]);

  const handleCreate = async () => {
    if (!newTitle.trim()) return;
    await todoApi.createTodo({ title: newTitle.trim(), entityRef });
    setNewTitle('');
    await loadTodos();
  };

  const handleToggle = async (todo: Todo) => {
    await todoApi.updateTodo(todo.id, { completed: !todo.completed });
    await loadTodos();
  };

  const handleDelete = async (id: string) => {
    await todoApi.deleteTodo(id);
    await loadTodos();
  };

  const openCount = todos.filter(t => !t.completed).length;

  return (
    <Card>
      <CardHeader
        title="Todos"
        subheader={`${openCount} open item${openCount !== 1 ? 's' : ''}`}
      />
      <CardContent>
        <Grid container spacing={1} alignItems="center">
          <Grid item xs>
            <TextField
              fullWidth
              size="small"
              variant="outlined"
              placeholder="Add a todo for this entity..."
              value={newTitle}
              onChange={(e) => setNewTitle(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleCreate()}
            />
          </Grid>
          <Grid item>
            <Button
              variant="contained"
              color="primary"
              size="small"
              onClick={handleCreate}
              disabled={!newTitle.trim()}
            >
              Add
            </Button>
          </Grid>
        </Grid>

        {todos.length === 0 ? (
          <Typography
            variant="body2"
            color="textSecondary"
            style={{ marginTop: 16, textAlign: 'center' }}
          >
            No todos yet. Add one above!
          </Typography>
        ) : (
          <List dense>
            {todos.map((todo) => (
              <ListItem key={todo.id} dense>
                <ListItemIcon>
                  <Checkbox
                    edge="start"
                    checked={todo.completed}
                    onChange={() => handleToggle(todo)}
                  />
                </ListItemIcon>
                <ListItemText
                  primary={todo.title}
                  style={{
                    textDecoration: todo.completed ? 'line-through' : 'none',
                    opacity: todo.completed ? 0.6 : 1,
                  }}
                />
                <ListItemSecondaryAction>
                  <IconButton edge="end" size="small" onClick={() => handleDelete(todo.id)}>
                    <DeleteIcon fontSize="small" />
                  </IconButton>
                </ListItemSecondaryAction>
              </ListItem>
            ))}
          </List>
        )}
      </CardContent>
    </Card>
  );
};
```

### Code Walkthrough

```typescript
const { entity } = useEntity();
...
const entityRef = stringifyEntityRef(entity);
```

**`useEntity()`** — A hook from `@backstage/plugin-catalog-react` that provides the current catalog entity when the component is rendered within an entity page context. It returns the full entity object including `metadata`, `spec`, `kind`, etc. This hook only works inside an entity page — using it elsewhere will throw an error.

**`stringifyEntityRef(entity)`** — Converts an entity object into its canonical string form: `kind:namespace/name` (e.g. `component:default/my-service`). This string is used as the key to associate todos with a specific entity. Using the canonical ref ensures consistency regardless of how the entity was originally referenced.


```typescript
<Card>
  <CardHeader ... />
  <CardContent>...</CardContent>
</Card>
```

**`Card` vs `Page`** — Unlike the TodoPage (which uses Backstage's `Page`/`Header`/`Content` layout), entity cards use standard Material UI `Card` components. Entity cards are rendered *inside* an existing page layout managed by the catalog plugin, so they don't need their own page wrapper.


## Task {{% param sectionnumber %}}.6: Define Routes

Create `plugins/todo/src/routes.ts`:

```typescript
import { createRouteRef } from '@backstage/frontend-plugin-api';

export const rootRouteRef = createRouteRef();
```

### Code Walkthrough

**`createRouteRef()`** — Creates a **route reference**, which is an abstract pointer to a URL path. Route refs decouple plugins from actual URLs: the plugin declares *that* it has a route, but the app decides *where* it lives. In the `PageBlueprint` (Task 7), you'll bind this ref to the path `/todo`. Other plugins can link to your page using this ref without hard-coding the URL.


## Task {{% param sectionnumber %}}.7: Wire Up the Plugin

Now let's connect everything using the new frontend system. The plugin definition declares **extensions** — self-contained units of functionality that the app discovers and installs automatically.

We use three types of extension blueprints:

| Blueprint | What it does |
|-----------|-------------|
| `ApiBlueprint` | Registers a Utility API factory. The API is available to all components in the plugin via `useApi(todoApiRef)`. Dependencies on other APIs (e.g. `discoveryApiRef`) are declared and injected automatically. |
| `PageBlueprint` | Adds a top-level route to the app. Automatically creates a **sidebar entry** with the given `title` (and optional `icon`). The component is **lazy-loaded** — it is only fetched when the user navigates to the page. |
| `EntityCardBlueprint` | Adds a card to entity pages in the catalog.  Like pages, the component is lazy-loaded. |

The plugin itself (`createFrontendPlugin`) ties extensions together and exposes route references that other plugins can link to.

Replace the content of `plugins/todo/src/plugin.tsx`:

```typescript
import {
  createFrontendPlugin,
  PageBlueprint,
  ApiBlueprint,
} from '@backstage/frontend-plugin-api';
import { EntityCardBlueprint } from '@backstage/plugin-catalog-react/alpha';
import { rootRouteRef } from './routes';
import { todoApiRef, LocalStorageTodoApi } from './api';
import { RiCheckboxLine } from '@remixicon/react';

const todoApi = ApiBlueprint.make({
  name: 'todo',
  params: defineParams =>
    defineParams({
      api: todoApiRef,
      deps: {},
      factory: () => new LocalStorageTodoApi(),
    }),
});

const todoPage = PageBlueprint.make({
  params: {
    routeRef: rootRouteRef,
    path: '/todo',
    title: 'Todo',
    icon: <RiCheckboxLine />,    
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

### Code Walkthrough

```typescript
const todoApi = ApiBlueprint.make({
  name: 'todo',
  params: defineParams =>
    defineParams({
      api: todoApiRef,
      deps: {},
      factory: () => new LocalStorageTodoApi(),
    }),
});
```

**`ApiBlueprint.make`** — Registers a Utility API factory with the app. When any component calls `useApi(todoApiRef)`, the framework invokes this `factory` function to provide the implementation. The `deps` object lets you declare dependencies on other APIs (e.g. `discoveryApiRef` for backend URLs) — they'll be injected into the factory.

```typescript
const todoPage = PageBlueprint.make({
  params: {
    ...
    loader: () => import('./components/TodoPage').then(m => <m.TodoPage />),
  },
});
```

**`loader` with dynamic `import()`** — The component is **lazy-loaded** using a dynamic import. This means the TodoPage code is split into a separate bundle chunk and only downloaded when the user navigates to `/todo`. This keeps the initial app bundle small. The `.then(m => <m.TodoPage />)` unwraps the module's named export and returns it as a JSX element.

```typescript
const entityTodoCard = EntityCardBlueprint.make({
  name: 'todo',
  params: {
    filter: 'kind:component,api,resource,system',
    ...
  },
});
```

**`filter`** — A catalog entity filter expression that controls *which* entity pages display this card. The format `kind:component,api,resource,system` means the card appears on Components, APIs, Resources, and Systems — but not on Users, Groups, or other kinds.

```typescript
export const todoPlugin = createFrontendPlugin({
  pluginId: 'todo',
  extensions: [todoApi, todoPage, entityTodoCard],
  routes: {
    root: rootRouteRef,
  },
});
```

**`createFrontendPlugin`** — The top-level plugin declaration that bundles all extensions together. The `routes` map exposes route refs so other plugins can link to your pages. The `extensions` array is what the app's feature discovery scans and installs.

## Task {{% param sectionnumber %}}.8: Export the Plugin

Update `plugins/todo/src/index.ts` to export the plugin as the **default export** (required for automatic feature discovery):

```typescript
export { todoPlugin as default } from './plugin';
export { todoApiRef } from './api';
export type { Todo, TodoApi } from './types';
```

### Code Walkthrough

**`todoPlugin as default`** — The plugin must be the **default export** of the package for Backstage's automatic feature discovery to find it. 

**Named exports (`todoApiRef`, types)** — These are exported for other plugins or packages that need to interact with the todo plugin programmatically (e.g. to call the API from another plugin, or to use the types in a shared library).

**`export type`** — The `type` keyword ensures that `Todo` and `TodoApi` are only exported as TypeScript type information. They are erased at compile time and produce no runtime JavaScript, keeping the bundle clean.


## Task {{% param sectionnumber %}}.9: Install Dependencies

The plugin needs a few peer dependencies. Run from your app root:

```bash
yarn --cwd plugins/todo add @backstage/frontend-plugin-api @backstage/core-components @backstage/plugin-catalog-react @backstage/catalog-model @material-ui/core @material-ui/icons
```


## Task {{% param sectionnumber %}}.10: Register the Plugin in the App

With the new frontend system and feature discovery enabled, the plugin is auto-discovered. Verify that your `app-config.yaml` contains:

```yaml
app:
  packages: all
```

If this setting exists, no code changes are needed in `packages/app/` — the plugin is automatically installed!

{{% alert title="Note" color="primary" %}}
If feature discovery is not enabled, you can manually install the plugin in `packages/app/src/App.tsx`:

```typescript
import { createApp } from '@backstage/frontend-defaults';
import todoPlugin from '../../../plugins/todo/src';

const app = createApp({
  features: [todoPlugin],
});
```
{{% /alert %}}


## Task {{% param sectionnumber %}}.11: Start and Verify

Start your Backstage app:

```bash
yarn start
```

You should now be able to:

1. Navigate to **`/todo`** to see the standalone Todo page
2. Open any component in the catalog and see the **Todos** card on the entity page
3. Create, complete, and delete todos

{{% alert title="Warning" color="secondary" %}}
Since we're using localStorage, todos are only stored in your browser. If you open a different browser or clear storage, the todos will be gone. We'll fix this with a proper backend in the next section.
{{% /alert %}}


### Standalone Plugin Development with the `dev/` Folder

You may have noticed a `dev/` directory inside `plugins/todo/`. This folder was scaffolded by `yarn new` and provides an **isolated development harness** for your plugin.

It typically contains a `dev/index.tsx` that sets up a minimal Backstage app with just your plugin loaded. You can start it with:

```bash
yarn --cwd plugins/todo start
```

This boots only the todo plugin — without starting the full Backstage backend and frontend — which makes for a **faster feedback loop** when iterating on your plugin's UI. It's especially useful when you want to:

- Develop and preview your plugin without the overhead of the entire monorepo
- Provide mock data or test providers specific to your plugin
- Run the plugin in complete isolation for debugging

{{% alert title="Note" color="primary" %}}
The `dev/` folder is optional and not required for the plugin to work within the full app. It is purely a convenience for plugin authors during development.
{{% /alert %}}


## Summary

In this section, you:

* ✅ Scaffolded a frontend plugin using the Backstage CLI
* ✅ Created a Utility API with a localStorage implementation
* ✅ Built a standalone Todo page using `PageBlueprint`
* ✅ Built an Entity Card using `EntityCardBlueprint`
* ✅ Wired everything together using `createFrontendPlugin`

The frontend plugin works completely standalone. In the next section, we'll add a backend plugin to persist todos in a database.
