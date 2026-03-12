---
title: "4. Extending the Portal with Existing Plugins"
weight: 4
sectionnumber: 4
---

Backstage's plugin ecosystem is what makes it truly powerful. Plugins extend Backstage with new functionality, integrations, and visualizations. In this chapter, you'll learn how to discover, install, and configure existing plugins to enhance your developer portal.

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
- **TechDocs**: Documentation platform
- **Cost Insights**: Cloud cost tracking
- **SonarQube**: Code quality metrics
- **PagerDuty**: On-call management
- **Grafana**: Metrics and dashboards


## Task {{% param sectionnumber %}}.2: Install the Kubernetes Plugin

Let's install the Kubernetes plugin to visualize cluster resources directly in Backstage.

**Step 1: Install the frontend plugin**

Navigate to your Backstage app directory and install the plugin:

```bash
cd packages/app
yarn add @backstage/plugin-kubernetes
```

**Step 2: Add the plugin to your app**

Edit `packages/app/src/components/catalog/EntityPage.tsx` and import the Kubernetes plugin:

```typescript
import { EntityKubernetesContent } from '@backstage/plugin-kubernetes';
```

Add a new tab to the service entity page:

```typescript
const serviceEntityPage = (
  <EntityLayout>
    <EntityLayout.Route path="/" title="Overview">
      {overviewContent}
    </EntityLayout.Route>
    
    <EntityLayout.Route path="/ci-cd" title="CI/CD">
      {cicdContent}
    </EntityLayout.Route>
    
    <EntityLayout.Route path="/kubernetes" title="Kubernetes">
      <EntityKubernetesContent refreshIntervalMs={30000} />
    </EntityLayout.Route>
    
    {/* ... other routes ... */}
  </EntityLayout>
);
```

**Step 3: Install the backend plugin**

```bash
cd packages/backend
yarn add @backstage/plugin-kubernetes-backend
```

**Step 4: Configure the backend**

Create `packages/backend/src/plugins/kubernetes.ts`:

```typescript
import { KubernetesBuilder } from '@backstage/plugin-kubernetes-backend';
import { Router } from 'express';
import { PluginEnvironment } from '../types';

export default async function createPlugin(
  env: PluginEnvironment,
): Promise<Router> {
  const { router } = await KubernetesBuilder.createBuilder({
    logger: env.logger,
    config: env.config,
  }).build();
  return router;
}
```

Register the plugin in `packages/backend/src/index.ts`:

```typescript
import kubernetes from './plugins/kubernetes';

// ... in the main function ...
const kubernetesEnv = useHotMemoize(module, () => createEnv('kubernetes'));
apiRouter.use('/kubernetes', await kubernetes(kubernetesEnv));
```

**Step 5: Configure Kubernetes clusters**

Add cluster configuration to `app-config.yaml`:

```yaml
kubernetes:
  serviceLocatorMethod:
    type: 'multiTenant'
  clusterLocatorMethods:
    - type: 'config'
      clusters:
        - url: https://your-cluster-api-server
          name: production
          authProvider: 'serviceAccount'
          serviceAccountToken: ${K8S_TOKEN}
          skipTLSVerify: false
          skipMetricsLookup: false
```

**Step 6: Annotate your components**

Add Kubernetes annotations to your component's `catalog-info.yaml`:

```yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: my-service
  annotations:
    backstage.io/kubernetes-id: my-service
    backstage.io/kubernetes-namespace: production
spec:
  type: service
  lifecycle: production
  owner: team-a
```

Now when you view this component in Backstage, you'll see a Kubernetes tab showing pods, deployments, and services!


## Task {{% param sectionnumber %}}.3: Install the GitHub Actions Plugin

Let's add CI/CD visibility with the GitHub Actions plugin.

**Step 1: Install the plugin**

```bash
cd packages/app
yarn add @backstage/plugin-github-actions
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


## Task {{% param sectionnumber %}}.4: Setup TechDocs Plugin

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


## Task {{% param sectionnumber %}}.5: Install a Monitoring Plugin (Grafana)

Let's add observability with the Grafana plugin.

**Step 1: Install the plugin**

```bash
cd packages/app
yarn add @backstage/plugin-grafana
```

**Step 2: Configure Grafana integration**

Add to `app-config.yaml`:

```yaml
grafana:
  domain: https://your-grafana-instance.com
  unifiedAlerting: true
```

**Step 3: Add to Entity Page**

Edit `packages/app/src/components/catalog/EntityPage.tsx`:

```typescript
import { EntityGrafanaDashboardsCard } from '@backstage/plugin-grafana';
```

Add to the overview content:

```typescript
const overviewContent = (
  <Grid container spacing={3} alignItems="stretch">
    {/* ... other cards ... */}
    
    <Grid item md={6}>
      <EntityGrafanaDashboardsCard />
    </Grid>
  </Grid>
);
```

**Step 4: Annotate components**

Add Grafana dashboard annotations:

```yaml
metadata:
  annotations:
    grafana/dashboard-selector: 'my-service-dashboard'
    grafana/alert-label-selector: 'service=my-service'
```


## Task {{% param sectionnumber %}}.6: Install the SonarQube Plugin

Add code quality metrics with SonarQube.

**Step 1: Install the plugin**

```bash
cd packages/app
yarn add @backstage/plugin-sonarqube
```

**Step 2: Install backend plugin**

```bash
cd packages/backend
yarn add @backstage/plugin-sonarqube-backend
```

**Step 3: Configure SonarQube**

Add to `app-config.yaml`:

```yaml
sonarqube:
  baseUrl: https://sonarqube.example.com
  apiKey: ${SONARQUBE_TOKEN}
```

**Step 4: Add to Entity Page**

```typescript
import { EntitySonarQubeCard } from '@backstage/plugin-sonarqube';

const overviewContent = (
  <Grid container spacing={3}>
    <Grid item md={6}>
      <EntitySonarQubeCard variant="gridItem" />
    </Grid>
  </Grid>
);
```

**Step 5: Annotate components**

```yaml
metadata:
  annotations:
    sonarqube.org/project-key: my-service
```


## Task {{% param sectionnumber %}}.7: Create a Custom Home Page with Plugins

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


## Task {{% param sectionnumber %}}.8: Configure Plugin Permissions

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
