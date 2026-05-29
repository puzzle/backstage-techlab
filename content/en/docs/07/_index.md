---
title: "7. Custom Plugin Development"
weight: 7
sectionnumber: 7
---

In this chapter, you will build a custom **Todo plugin** for Backstage from scratch. The plugin allows users to create and manage todo items that are associated with catalog entities. Todos will appear both on a standalone page and directly on entity pages in the catalog.

This is structured in three parts that build on each other:

1. **Frontend Plugin** — Create a working Todo UI with local storage (~45 min)
2. **Backend Plugin** — Add a persistent REST API with database (~45 min)
3. **API Integration and Testing** — Connect frontend to backend, write tests (~30 min)

Each part results in a working solution, so you can stop after the frontend part and still have a functional plugin.

{{% alert title="Note" color="primary" %}}
This chapter uses the **new Frontend System** (`@backstage/frontend-plugin-api`) and the **new Backend System** (`@backstage/backend-plugin-api`). These are the current recommended approaches for plugin development in Backstage.
{{% /alert %}}


## Architecture Overview

The Todo plugin consists of three packages:

```text
plugins/
├── todo/                 # Frontend plugin
│   └── src/
│       ├── plugin.ts     # Plugin definition with extensions
│       ├── api.ts        # API client (Utility API)
│       ├── routes.ts     # Route references
│       └── components/   # React components
├── todo-backend/         # Backend plugin
│   └── src/
│       ├── plugin.ts     # Backend plugin definition
│       ├── router.ts     # Express router with REST endpoints
│       └── database.ts   # Database access layer
└── todo-common/          # Shared types (optional)
    └── src/
        └── types.ts      # Todo interface, API interface
```

The data model is simple:

| Field | Type | Description |
| ------- | ------ | ------------- |
| `id` | `string` | Unique identifier (UUID) |
| `title` | `string` | Todo description |
| `entityRef` | `string` | Catalog entity reference (e.g. `component:default/my-service`) |
| `createdAt` | `string` | ISO timestamp |
| `completed` | `boolean` | Completion status |

