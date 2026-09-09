---
title: "5.3.1 Fill the Catalog with Providers"
weight: 531
sectionnumber: 5.3.1
---

## Task {{% param sectionnumber %}}.1: Use Github-Catalog Providers

Backstage can automatically discover and import entities from various sources.

Let's configure GitHub discovery to automatically find all repositories with `catalog-info.yaml` files.


### Step 1: Install the plugin

```bash
# From your Backstage root directory
yarn --cwd packages/backend add @backstage/plugin-catalog-backend-module-github
```

Update your backend by adding the following lines inside `packages/backend/src/index.ts`:

```bash
// GitHub catalog plugin
backend.add(import('@backstage/plugin-catalog-backend-module-github'));
```


### Step 2: Configure the catalog provider

Check that the GitHub integration is configured like this in your `app-config.yaml`:

```yaml
integrations:
  github:
    - host: github.com
      token: ${GITHUB_TOKEN}
```

You should have created the `GITHUB_TOKEN` in the lab [GitHub Integration](../../../03/additional/github/).

Edit your `app-config.yaml` to enable the GitHub catalog provider:

```yaml
catalog:
  providers:
    github:
      myOrg:
        organization: 'your-github-org'  # Replace with your GitHub organization or username
        catalogPath: '/catalog-info.yaml'
        filters:
          branch: 'main'
          repository: '.*'  # Regex to match all repositories
        schedule:
          frequency: { minutes: 30 }
          timeout: { minutes: 3 }
```


### Step 3: Restart Backstage

Restart your Backstage instance to apply the changes:

```bash
yarn start
```

This configuration will automatically discover all repositories in your GitHub organization that contain a `catalog-info.yaml` file and refresh every 30 minutes!


### Step 4: Find the provided entities

* Checkout the new created `Location` entity for GitHub
* Navigate to `Inspect Entity` and checkout the annotations for GitHub
