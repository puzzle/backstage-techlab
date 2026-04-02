---
title: "4. Extending the Portal with Existing Plugins"
weight: 4
sectionnumber: 4
---

Plugins extend Backstage with new functionality, integrations, and visualizations.

In this chapter, you'll learn how to discover, install, and configure existing plugins to enhance your developer portal.

TODO CRA: simple plugins, take todo app

TODO CRA: github tasks as advanced tasks

TODO CRA: home page task in a new lab: change look and feel / adapt to company cooperate design

## Understanding the Plugin Ecosystem

Backstage has a rich ecosystem of plugins that fall into several categories:

* **Frontend Plugins**: Add new pages and UI components to the Backstage interface
* **Backend Plugins**: Provide APIs and backend services
* **Scaffolder Actions**: Extend software templates with custom actions
* **Catalog Processors**: Add custom logic for processing catalog entities

{{% alert title="Note" color="primary" %}}
Most plugins are open source and maintained by the Backstage community. You can find them in the [Backstage Plugin Marketplace](https://backstage.io/plugins) or on npm.
{{% /alert %}}


## Task {{% param sectionnumber %}}.1: Explore Available Plugins

Before installing plugins, let's explore what's available.

Visit the Backstage Plugin Marketplace:

* Go to [https://backstage.io/plugins](https://backstage.io/plugins)
* Browse categories like CI/CD, Monitoring, Cloud, Security, etc.
* Note plugins that would be useful for your organization

Popular plugins include:

* **Kubernetes**: View and manage Kubernetes resources
* **GitHub Actions**: Monitor CI/CD pipelines
* **Gitlab CI/CD**: Monitor CI/CD pipelines
* **TechDocs**: Documentation platform
* **Grafana**: Metrics and dashboards
* **ArgoCD**: CD pipeline visualization


## Task {{% param sectionnumber %}}.2: Use Github-Catalog Processors

Backstage can automatically discover and import entities from various sources.

Let's configure GitHub discovery to automatically find all repositories with `catalog-info.yaml` files.


### Step 1: Install the plugin

```bash
# From your Backstage root directory
yarn --cwd packages/backend add @backstage/plugin-catalog-backend-module-github
```

Update your backend by adding the following line:

```bash
# packages/backend/src/index.ts
backend.add(import('@backstage/plugin-catalog-backend-module-github'));
```


### Step 2: Configure GitHub integration

Edit your `app-config.yaml` to add GitHub integration:

```yaml
integrations:
  github:
    - host: github.com
      token: ${GITHUB_TOKEN}

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


### Step 4: Find the provided entites

* Checkout the new created `Location` entity for GitHub
* Navigate to `Inspect Entity` and checkout the annotations for GitHub


## Task {{% param sectionnumber %}}.2: Setup TechDocs Plugin

TechDocs brings documentation directly into Backstage, making it easy for developers to find and read documentation alongside their services. TechDocs is already included by default, but let's configure it properly and add documentation to a component.


### Step 1: Configure TechDocs for local development

Edit `app-config.yaml`:

```yaml
techdocs:
  builder: 'local'
  generator:
    runIn: 'local'
  publisher:
    type: 'local'
```


### Step 2: Create documentation

In your `my-sample-service` directory (or any catalog component), create a `docs/` folder:

```bash
mkdir -p ~/my-sample-service/docs
```

Create `docs/index.md`:

```markdown
# My Sample Service

## Overview

This is a sample microservice that demonstrates Backstage catalog integration.

## Architecture

The service is built with Node.js and provides a REST API for user management.

## Getting Started

### Prerequisites

* Node.js 22+
* PostgreSQL 14+

### Installation

\`\`\`bash
npm install
npm start
\`\`\`

## API Documentation

See the [API Reference](./api.md) for detailed endpoint documentation.
```


### Step 3: Create MkDocs configuration

Create a `mkdocs.yml` file in the root of your service:

```yaml
site_name: 'My Sample Service'
site_description: 'Documentation for My Sample Service'

nav:
  - Home: index.md

plugins:
  - techdocs-core
```


### Step 4: Enable TechDocs in catalog

Update your `catalog-info.yaml` to enable TechDocs:

```yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: my-sample-service
  description: A sample microservice for the Backstage catalog
  annotations:
    github.com/project-slug: your-org/my-sample-service
    backstage.io/techdocs-ref: dir:.
  tags:
    - nodejs
    - microservice
spec:
  type: service
  lifecycle: production
  owner: team-a
  system: my-system
```

Now your documentation will be available directly in Backstage under the "Docs" tab of your component!

{{% alert title="Note" color="primary" %}}
The `backstage.io/techdocs-ref: dir:.` annotation tells Backstage where to find the documentation. Use `dir:.` for docs in the same repository, or specify a URL for external documentation sources.
{{% /alert %}}


## Task {{% param sectionnumber %}}.3: Install the GitHub Actions Plugin

Let's add CI/CD visibility with the GitHub Actions plugin.


### Step 1: Install and configure the plugin

```bash
yarn --cwd packages/app add @backstage/plugin-github-actions
```

Edit `packages/app/src/components/catalog/EntityPage.tsx`:

```typescript
import {
  EntityGithubActionsContent,
  isGithubActionsAvailable,
} from '@backstage/plugin-github-actions';
```

Add the CI/CD tab to the existing constant:

```typescript
const cicdContent = (
  <EntitySwitch>
    <EntitySwitch.Case if={isGithubActionsAvailable}>
      <EntityGithubActionsContent />
    </EntitySwitch.Case>
  </EntitySwitch>
);
```

Enable the GitHub auth provider in the backend:

```bash
# In packages/backend/src/index.ts
backend.add(
  import('@backstage/plugin-auth-backend-module-github-provider')
);
```


### Step 2: Register a GitHub OAuth app

To enable integration with GitHub, you need to register a GitHub OAuth app. This enables Backstage to authenticate users and access GitHub repositories on their behalf.

1. Go to GitHub Settings: [https://github.com/settings/developers](https://github.com/settings/developers)
2. Click **"New OAuth App"**
3. Fill in the form:
   * **Application name**: Backstage
   * **Homepage URL**: http://localhost:3000
   * **Authorization callback URL**: http://localhost:7007/api/auth/github/handler/frame
4. Click **"Register application"**
5. Note the **Client ID** and **Client Secret**


Add the following to your `app-config.local.yaml`:

```yaml
auth:
  environment: development
  providers:
    github:
      development:
        clientId: ${AUTH_GITHUB_CLIENT_ID}
        clientSecret: ${AUTH_GITHUB_CLIENT_SECRET}
        signIn:
          resolvers:
            - resolver: usernameMatchingUserEntityName
              dangerouslyAllowSignInWithoutUserInCatalog: true
```


### Step 3: Restart Backstage

Restart your Backstage instance to apply the changes:

```bash
yarn start
```

Find your Full-Stack Application created with the template in chapter 3.2. You should now see the GitHub workflow in the CI/CD tab.

![GitHub Workflow](/docs/04/github_workflow.png)


{{% onlyWhen fullScope %}}


## Task {{% param sectionnumber %}}.4: Configure Plugin Permissions

Backstage supports fine-grained permissions. Let's configure who can access what.


### Step 1: Install permissions plugins

```bash
cd packages/backend
yarn add @backstage/plugin-permission-backend
yarn add @backstage/plugin-permission-node
```


### Step 2: Create permission policy

Create `packages/backend/src/plugins/permission.ts`:

```typescript
import { createRouter } from '@backstage/plugin-permission-backend';
import { Router } from 'express';
import { PluginEnvironment } from '../types';
import { PolicyDecision } from '@backstage/plugin-permission-common';

class CustomPermissionPolicy {
  async handle(request: any): Promise<PolicyDecision> {
    // Define your permission logic here
    if (request.permission.name === 'catalog.entity.delete') {
      // Only admins can delete entities
      return { result: 'CONDITIONAL' };
    }
    return { result: 'ALLOW' };
  }
}

export default async function createPlugin(
  env: PluginEnvironment,
): Promise<Router> {
  return await createRouter({
    config: env.config,
    logger: env.logger,
    discovery: env.discovery,
    policy: new CustomPermissionPolicy(),
  });
}
```
{{% /onlyWhen %}}


## Best Practices for Plugin Management

1. **Start with essential plugins**: Don't install everything at once
2. **Read documentation**: Each plugin has specific configuration requirements
3. **Test in development**: Always test plugins locally before production
4. **Monitor performance**: Some plugins can impact load times
5. **Keep plugins updated**: Regularly update to get bug fixes and features
6. **Use semantic versioning**: Pin major versions to avoid breaking changes
7. **Configure authentication**: Ensure plugins respect your auth setup
8. **Document customizations**: Keep notes on configuration changes


## Troubleshooting Common Plugin Issues

**Plugin not appearing:**

* Check that you've added it to the correct Entity Page
* Verify the component has required annotations
* Check browser console for errors

**Backend plugin errors:**

* Ensure backend plugin is registered in `index.ts`
* Verify configuration in `app-config.yaml`
* Check backend logs for detailed errors

**Authentication issues:**

* Verify integration tokens are set correctly
* Check token permissions/scopes
* Ensure environment variables are loaded


## Summary

In this chapter, you:

* ✅ Explored the Backstage plugin ecosystem
* ✅ Configured GitHub catalog processors for automatic entity discovery
* ✅ Set up TechDocs for component documentation
* ✅ Installed and configured the GitHub Actions plugin for CI/CD visibility
* ✅ Customized the home page with plugin widgets

Plugins are what make Backstage adaptable to your organization's needs. By carefully selecting and configuring plugins, you create a developer portal that truly reduces cognitive load and improves the developer experience.


## Next Steps

Now that you've completed this techlab, you're ready to:

1. **Identify your organization's needs**: What tools do your developers use daily?
2. **Plan your plugin strategy**: Which plugins would provide the most value?
3. **Build custom plugins**: Create plugins for internal tools and services
4. **Roll out to teams**: Start with a pilot team and gather feedback
5. **Iterate and improve**: Continuously enhance your developer portal

**Congratulations!** You now have the knowledge to install, customize, and extend Backstage to massively improve Developer Experience in your organization.  
