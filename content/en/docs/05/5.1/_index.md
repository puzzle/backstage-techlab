---
title: "5.1 Introduction to Plugin usage"
weight: 51
sectionnumber: 5.1
---

Plugins extend Backstage with new functionality, integrations, and visualizations.

In this chapter, you'll learn how to discover, install, and configure existing plugins to enhance your developer portal.

TODO CRA: simple plugins, take todo app?


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


## Task {{% param sectionnumber %}}.2: Setup TechDocs Plugin

[TechDocs](http://backstage.io/docs/features/techdocs/) brings documentation directly into Backstage, making it easy for developers to find and read documentation alongside their services. TechDocs is already included by default, but let's configure it properly and add documentation to a component.


### Step 1: Configure TechDocs for local development

Make sure that your `app-config.yaml` is configured for TechDocs:

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
mkdir -p examples/my-sample-service/docs
```

Create `docs/index.md`:

{{< readfile file="/manifests/04/4.1/docs/index.md" code="true" lang="markdown" >}}


### Step 3: Create MkDocs configuration

Create a `mkdocs.yml` file in the root of your service:

{{< readfile file="/manifests/04/4.1/mkdocs.yml" code="true" lang="yaml" >}}


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
