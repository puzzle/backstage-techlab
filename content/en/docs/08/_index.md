---
title: "8. Integrated Search"
weight: 8
sectionnumber: 8
---

Backstage ships with a built-in search system that provides a unified search experience across all content in your developer portal. Instead of navigating through multiple sections to find something, developers can search catalog entities, documentation, and any other indexed content from a single place.

This chapter covers how search works, what gets indexed by default, and how to configure the search backend for production use.


## How Backstage Search Works

The search system consists of three main building blocks:

| Building Block | Role |
| --- | --- |
| **Search Engine** | Stores and queries the search index (Lunr by default, Elasticsearch/OpenSearch for production) |
| **Collators** | Gather and transform data from different sources into indexable documents |
| **Decorators** | Enrich indexed documents with additional metadata before they are stored |

At startup, the backend scheduler runs all registered collators, which feed their documents into the search engine. The frontend queries the search API and renders results using registered result extensions.

{{% alert title="Note" color="primary" %}}
Backstage uses [Lunr](https://lunrjs.com/) as the default search engine. It is fully in-memory and requires no external infrastructure, making it ideal for development. For production workloads, replace it with [Elasticsearch/OpenSearch](https://backstage.io/docs/features/search/search-engines/#elasticsearch).
{{% /alert %}}


## Task {{% param sectionnumber %}}.1: Explore the Search UI

Let's start by using the search feature that is already part of your Backstage app.

1. Open your Backstage instance at [http://localhost:3000](http://localhost:3000)
2. Click the 🔍 icon in the left sidebar to open the search page, or navigate directly to [http://localhost:3000/search](http://localhost:3000/search)
3. Try a few searches:
   * Type `example` to find the default catalog entities
   * Type `platform` to find Platform Engineers (users)
   * Type `template` to find the example scaffolder template

The search results show the entity name, kind, and a short description. Clicking a result navigates directly to that entity or document.


## Task {{% param sectionnumber %}}.2: Understand the Default Collators

Out of the box, Backstage indexes the following content:

| Collator | Package | What it indexes |
| --- | --- | --- |
| `DefaultCatalogCollatorFactory` | `@backstage/plugin-search-backend-module-catalog` | All catalog entities (components, APIs, systems, etc.) |
| `DefaultTechDocsCollatorFactory` | `@backstage/plugin-search-backend-module-techdocs` | TechDocs pages and their content |

Both collators are registered automatically when you create a new Backstage app.

To verify, open `packages/backend/src/index.ts` and look for the search module imports:

```typescript
backend.add(import('@backstage/plugin-search-backend'));
backend.add(import('@backstage/plugin-search-backend-module-catalog'));
backend.add(import('@backstage/plugin-search-backend-module-techdocs'));
```

The search engine processes catalog and TechDocs content automatically on each refresh cycle (default: every 10 minutes).


## Task {{% param sectionnumber %}}.3: Configure the Search Schedule

The collator refresh interval can be configured in `app-config.yaml`. Add the following to adjust the schedule:

```yaml
search:
  collators:
    catalog:
      schedule:
        frequency:
          minutes: 10
        timeout:
          minutes: 15
    techdocs:
      schedule:
        frequency:
          minutes: 30
        timeout:
          minutes: 15
```

{{% alert title="Tip" color="primary" %}}
During development, set a shorter frequency (e.g., 1 minute) so that new or updated catalog entities appear in search results quickly without restarting the app.
{{% /alert %}}

More configuration options can be found here: https://backstage.io/docs/features/search/collators/#catalog


<!-- 
## Task {{% param sectionnumber %}}.4: Switch to Elasticsearch (Production Setup)

For production use, replace the default in-memory Lunr engine with Elasticsearch. This gives you persistent indexes, better performance, and support for larger catalogs.


### Step 1: Install the Elasticsearch backend module

```bash
yarn --cwd packages/backend add @backstage/plugin-search-backend-module-elasticsearch
```


### Step 2: Register the Elasticsearch engine

In `packages/backend/src/index.ts`, replace the default search engine registration:

```typescript
// Remove or comment out:
// backend.add(import('@backstage/plugin-search-backend'));

// Add:
backend.add(import('@backstage/plugin-search-backend-module-elasticsearch'));
```


### Step 3: Configure the connection in `app-config.yaml`

```yaml
search:
  elasticsearch:
    provider: elastic
    elastic:
      node: http://localhost:9200
      auth:
        username: elastic
        password: changeme
```

{{% alert title="Note" color="primary" %}}
For local testing you can spin up Elasticsearch with Docker:

```bash
docker run -d --name elasticsearch \
  -e "discovery.type=single-node" \
  -e "ELASTIC_PASSWORD=changeme" \
  -e "xpack.security.enabled=true" \
  -p 9200:9200 \
  docker.elastic.co/elasticsearch/elasticsearch:8.13.0
```
{{% /alert %}}

After restarting Backstage, the search index is built and persisted in Elasticsearch. Subsequent restarts are faster because the index already exists.


## Search Result Types

Each collator registers its own result type. The frontend renders results differently depending on the type:

| Result type | Rendered as |
| --- | --- |
| `software-catalog` | Entity card with kind badge, owner, and description |
| `techdocs` | Documentation page link with breadcrumb path |
| custom | Any format you define in your own result extension |


-->


## Summary

In this chapter, you:

* Explored the built-in Backstage search UI
* Learned about collators and how catalog and TechDocs content is indexed
* Configured the collator refresh schedule
* Understood how to replace the default Lunr engine with Elasticsearch for production

Backstage Search grows with your portal. As you add more plugins and data sources, you can register additional collators to make all content searchable from one place.


## Next Steps

Now that you've completed this lab, you could:

1. **Write a custom collator**: Index content from an internal wiki, Confluence, or any other data source by implementing the `DocumentCollatorFactory` interface. See the [official docs](https://backstage.io/docs/features/search/collators) for details.
2. **Customize result rendering**: Register a custom `SearchResultListItemExtension` to control how your search results are displayed.
3. **Add filters**: Use `SearchFilter` components to let users narrow results by entity kind, namespace, or any other metadata field.
