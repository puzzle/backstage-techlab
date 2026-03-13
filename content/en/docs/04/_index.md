---
title: "4. Extending the Portal with Existing Plugins"
weight: 4
sectionnumber: 4
---

Plugins extend Backstage with new functionality, integrations, and visualizations. In this chapter, you'll learn how to discover, install, and configure existing plugins to enhance your developer portal.

## Understanding the Plugin Ecosystem

Backstage has a rich ecosystem of plugins that fall into several categories:

- **Frontend Plugins**: Add new pages and UI components to the Backstage interface
- **Backend Plugins**: Provide APIs and backend services
- **Scaffolder Actions**: Extend software templates with custom actions
- **Catalog Processors**: Add custom logic for processing catalog entities

{{% alert title="Note" color="primary" %}}
Most plugins are open source and maintained by the Backstage community. You can find them in the [Backstage Plugin Marketplace](https://backstage.io/plugins) or on npm.
{{% /alert %}}


## Task {{% param sectionnumber %}}.1: Explore Available Plugins

Before installing plugins, let's explore what's available.

Visit the Backstage Plugin Marketplace:
- Go to [https://backstage.io/plugins](https://backstage.io/plugins)
- Browse categories like CI/CD, Monitoring, Cloud, Security, etc.
- Note plugins that would be useful for your organization

Popular plugins include:
- **Kubernetes**: View and manage Kubernetes resources
- **GitHub Actions**: Monitor CI/CD pipelines
- **Gitlab CI/CD**: Monitor CI/CD pipelines
- **TechDocs**: Documentation platform
- **Grafana**: Metrics and dashboards
- **ArgoCD**: CD pipeline visualization



## Task {{% param sectionnumber %}}.2: Use Github-Catalog Processors

Backstage can automatically discover and import entities from various sources. 


Let's configure GitHub discovery to automatically find all repositories with `catalog-info.yaml` files.

### Step 1: Install and configure plugin

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


- Checkout the new created `Location` entity for GitHub
- Navigate to `Inspect Entity` and checkout the annotations for GitHub


## Task {{% param sectionnumber %}}.2: Install the GitHub Actions Plugin

Let's add CI/CD visibility with the GitHub Actions plugin.

**Step 1: Install the plugin**

```bash
yarn --cwd packages/app add @backstage/plugin-github-actions
```

**Step 2: Add to the Entity Page**

Edit `packages/app/src/components/catalog/EntityPage.tsx`:

```typescript
import {
  EntityGithubActionsContent,
  isGithubActionsAvailable,
} from '@backstage/plugin-github-actions';
```

Add the CI/CD tab:

```typescript
const cicdContent = (
  <EntitySwitch>
    <EntitySwitch.Case if={isGithubActionsAvailable}>
      <EntityGithubActionsContent />
    </EntitySwitch.Case>
  </EntitySwitch>
);
```

**Step 3: Configure GitHub integration**

Ensure your `app-config.yaml` has GitHub integration configured:

```yaml
integrations:
  github:
    - host: github.com
      token: ${GITHUB_TOKEN}
```

**Step 4: Annotate components**

Add the GitHub annotation to your `catalog-info.yaml`:

```yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: my-service
  annotations:
    github.com/project-slug: your-org/your-repo
spec:
  type: service
  lifecycle: production
  owner: team-a
```

Now you can see GitHub Actions workflow runs directly in Backstage!


## Task {{% param sectionnumber %}}.3: Setup TechDocs Plugin

TechDocs brings documentation directly into Backstage, making it easy for developers to find and read documentation alongside their services. TechDocs is already included by default, but let's configure it properly and add documentation to a component.

**Step 1: Configure TechDocs for local development**

Edit `app-config.yaml`:

```yaml
techdocs:
  builder: 'local'
  generator:
    runIn: 'local'
  publisher:
    type: 'local'
```

**Step 2: Create documentation for a component**

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

- Node.js 22+
- PostgreSQL 14+

### Installation

\`\`\`bash
npm install
npm start
\`\`\`

## API Documentation

See the [API Reference](./api.md) for detailed endpoint documentation.
```

**Step 3: Create MkDocs configuration**

Create a `mkdocs.yml` file in the root of your service:

```yaml
site_name: 'My Sample Service'
site_description: 'Documentation for My Sample Service'

nav:
  - Home: index.md

plugins:
  - techdocs-core
```

**Step 4: Enable TechDocs in catalog**

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

**Step 5: Production configuration (optional)**

For production deployments, use external storage:

```yaml
techdocs:
  builder: 'external'
  generator:
    runIn: 'docker'
  publisher:
    type: 'awsS3'
    awsS3:
      bucketName: 'my-techdocs-bucket'
      region: 'us-east-1'
      credentials:
        accessKeyId: ${AWS_ACCESS_KEY_ID}
        secretAccessKey: ${AWS_SECRET_ACCESS_KEY}
```

{{% alert title="Note" color="primary" %}}
The `backstage.io/techdocs-ref: dir:.` annotation tells Backstage where to find the documentation. Use `dir:.` for docs in the same repository, or specify a URL for external documentation sources.
{{% /alert %}}



## Task {{% param sectionnumber %}}.4: Create a Custom Home Page with Plugins

Let's customize the Backstage home page to show useful information.

Edit `packages/app/src/components/home/HomePage.tsx`:

```typescript
import React from 'react';
import { Content, Header, Page } from '@backstage/core-components';
import { HomePageSearchBar } from '@backstage/plugin-search';
import { HomePageStarredEntities } from '@backstage/plugin-home';
import { Grid } from '@material-ui/core';

export const HomePage = () => {
  return (
    <Page themeId="home">
      <Header title="Welcome to Your Developer Portal" />
      <Content>
        <Grid container spacing={3}>
          <Grid item xs={12}>
            <HomePageSearchBar />
          </Grid>
          
          <Grid item xs={12} md={6}>
            <HomePageStarredEntities />
          </Grid>
          
          <Grid item xs={12} md={6}>
            {/* Add custom widgets here */}
          </Grid>
        </Grid>
      </Content>
    </Page>
  );
};
```

{{% onlyWhen fullScope %}}

## Task {{% param sectionnumber %}}.5: Configure Plugin Permissions

Backstage supports fine-grained permissions. Let's configure who can access what.

**Step 1: Install permissions plugins**

```bash
cd packages/backend
yarn add @backstage/plugin-permission-backend
yarn add @backstage/plugin-permission-node
```

**Step 2: Create permission policy**

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


## Popular Plugin Combinations

Here are some recommended plugin combinations for different use cases:

**Platform Engineering Team:**
- Kubernetes
- GitHub Actions
- TechDocs
- Cost Insights
- Grafana

**Application Development Team:**
- GitHub Actions
- SonarQube
- TechDocs
- Rollbar/Sentry
- Lighthouse (for web apps)

**Data Engineering Team:**
- Airflow
- DataDog
- TechDocs
- Cost Insights


## Troubleshooting Common Plugin Issues

**Plugin not appearing:**
- Check that you've added it to the correct Entity Page
- Verify the component has required annotations
- Check browser console for errors

**Backend plugin errors:**
- Ensure backend plugin is registered in `index.ts`
- Verify configuration in `app-config.yaml`
- Check backend logs for detailed errors

**Authentication issues:**
- Verify integration tokens are set correctly
- Check token permissions/scopes
- Ensure environment variables are loaded


## Summary

In this chapter, you:
- ✅ Explored the Backstage plugin ecosystem
- ✅ Installed and configured the Kubernetes plugin
- ✅ Added GitHub Actions for CI/CD visibility
- ✅ Configured TechDocs for production
- ✅ Integrated monitoring with Grafana
- ✅ Added code quality metrics with SonarQube
- ✅ Customized the home page
- ✅ Learned about plugin permissions

Plugins are what make Backstage adaptable to your organization's needs. By carefully selecting and configuring plugins, you create a developer portal that truly reduces cognitive load and improves the developer experience.


## Next Steps

Now that you've completed this techlab, you're ready to:

1. **Identify your organization's needs**: What tools do your developers use daily?
2. **Plan your plugin strategy**: Which plugins would provide the most value?
3. **Build custom plugins**: Create plugins for internal tools and services
4. **Roll out to teams**: Start with a pilot team and gather feedback
5. **Iterate and improve**: Continuously enhance your developer portal

**Congratulations!** You now have the knowledge to install, customize, and extend Backstage to massively improve Developer Experience in your organization.  
