---
title: "4. Extending the Portal with Existing Plugins"
weight: 4
sectionnumber: 4
---

Plugins extend Backstage with new functionality, integrations, and visualizations. In this chapter, you'll learn how to discover, install, and configure existing plugins to enhance your developer portal.


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


## Task {{% param sectionnumber %}}.4: Create a Custom Home Page

Let's customize the Backstage home page with a congratulatory message.

Create `packages/app/src/components/home/HomePage.tsx`:

```typescript
import { Content, Header, Page } from '@backstage/core-components';
import { Grid, Typography, Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';

const useStyles = makeStyles((theme) => ({
  congratsContainer: {
    textAlign: 'center',
    padding: theme.spacing(8, 2),
  },
  logo: {
    marginBottom: theme.spacing(4),
  },
  message: {
    marginTop: theme.spacing(3),
    color: theme.palette.text.secondary,
  },
}));

export const HomePage = () => {
  const classes = useStyles();
  
  return (
    <Page themeId="home">
      <Header title="Welcome to Your Developer Portal" />
      <Content>
        <Grid container spacing={3}>
          <Grid item xs={12}>
            <Box className={classes.congratsContainer}>
              <div className={classes.logo}>
                <svg width="310px" height="80px" viewBox="0 0 310 80" version="1.1" xmlns="http://www.w3.org/2000/svg">
                  <title>Puzzle ITC</title>
                  <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
                    <g fill="#9CC9FF">
                      <path d="M102.863636,42.8364912 L107.93011,42.8364912 C109.403315,42.8364912 110.526696,42.4336842 111.296028,41.6245614 C112.066769,40.8161404 112.451787,39.7775439 112.451787,38.5080702 C112.451787,37.2112281 112.066769,36.1494737 111.296028,35.3214035 C110.526696,34.4926316 109.403315,34.0785965 107.93011,34.0785965 L102.863636,34.0785965 L102.863636,42.8364912 Z M102.863636,48.0477193 L102.863636,58.0477193 L96.0494474,58.0477193 L96.0494474,28.8673684 L107.93011,28.8673684 C111.400201,28.8673684 114.154454,29.7536842 116.190757,31.522807 C118.229172,33.2947368 119.247675,35.6091228 119.247675,38.4680702 C119.247675,41.3410526 118.229172,43.6561404 116.190757,45.4133333 C114.154454,47.1691228 111.400201,48.0477193 107.93011,48.0477193 L102.863636,48.0477193 Z M146.12434,28.8675088 L146.12434,47.9875088 C146.12434,51.3152281 145.015037,53.8934737 142.797135,55.7243509 C140.579937,57.5538246 137.675056,58.4682105 134.084602,58.4682105 C130.452621,58.4682105 127.524511,57.5538246 125.29957,55.7243509 C123.075333,53.8934737 121.961807,51.3152281 121.961807,47.9875088 L121.961807,28.8675088 L128.7767,28.8675088 L128.7767,47.9875088 C128.7767,49.778386 129.239848,51.104 130.164033,51.9664561 C131.088217,52.826807 132.395308,53.258386 134.084602,53.258386 C135.759115,53.258386 137.047905,52.8310175 137.953085,51.9755789 C138.857561,51.1201404 139.309447,49.7910175 139.309447,47.9875088 L139.309447,28.8675088 L146.12434,28.8675088 Z M157.164298,52.8378246 L170.492826,52.8378246 L170.492826,58.0476491 L148.802293,58.0476491 L148.802293,55.0020351 L161.88869,34.0785263 L148.742464,34.0785263 L148.742464,28.8672982 L170.312635,28.8672982 L170.312635,31.793614 L157.164298,52.8378246 Z M180.981159,52.8378246 L194.308984,52.8378246 L194.308984,58.0476491 L172.619859,58.0476491 L172.619859,55.0020351 L185.706255,34.0785263 L172.558622,34.0785263 L172.558622,28.8672982 L194.128792,28.8672982 L194.128792,31.793614 L180.981159,52.8378246 Z M203.672106,52.8378246 L216.275646,52.8378246 L216.275646,58.0476491 L196.856509,58.0476491 L196.856509,28.8672982 L203.672106,28.8672982 L203.672106,52.8378246 Z M236.928671,45.5626667 L225.449919,45.5626667 L225.449919,52.8377544 L238.978348,52.8377544 L238.978348,58.0475789 L218.636434,58.0475789 L218.636434,28.8672281 L239.018468,28.8672281 L239.018468,34.0784561 L225.449919,34.0784561 L225.449919,40.3514386 L236.928671,40.3514386 L236.928671,45.5626667 Z M259.540995,58.0477193 L252.766927,58.0477193 L252.766927,28.8673684 L259.540995,28.8673684 L259.540995,58.0477193 Z M284.27099,34.0785965 L276.551621,34.0785965 L276.551621,58.0477193 L269.736728,58.0477193 L269.736728,34.0785965 L262.078596,34.0785965 L262.078596,28.8673684 L284.27099,28.8673684 L284.27099,34.0785965 Z M309.071513,47.8077193 L309.111634,47.9270175 C308.977195,51.3480702 307.960803,53.9592982 306.065978,55.7642105 C304.167634,57.5677193 301.418308,58.4680702 297.813778,58.4680702 C294.195873,58.4680702 291.25439,57.3592982 288.989329,55.1417544 C286.724267,52.9242105 285.591737,50.0449123 285.591737,46.5045614 L285.591737,40.4119298 C285.591737,36.8842105 286.679923,34.0084211 288.859113,31.7845614 C291.036894,29.56 293.865757,28.4470175 297.352037,28.4470175 C301.050183,28.4470175 303.876935,29.3761404 305.832292,31.2322807 C307.791169,33.0905263 308.895545,35.7284211 309.150347,39.1494737 L309.111634,39.2694737 L302.497345,39.2694737 C302.403026,37.3719298 301.977887,35.962807 301.22052,35.0407018 C300.463857,34.1185965 299.172955,33.6575439 297.352037,33.6575439 C295.809853,33.6575439 294.597081,34.2757895 293.712313,35.5122807 C292.828953,36.7487719 292.386217,38.3677193 292.386217,40.3719298 L292.386217,46.5045614 C292.386217,48.5221053 292.869074,50.1529825 293.834083,51.394386 C294.798388,52.6378947 296.124484,53.2589474 297.813778,53.2589474 C299.448873,53.2589474 300.608151,52.8238596 301.291611,51.9550877 C301.974368,51.0877193 302.363609,49.7045614 302.45652,47.8077193 L309.071513,47.8077193 Z M11.6887872,68.3477193 C-3.89635626,52.8101754 -3.89635626,27.62 11.6887872,12.0831579 C27.2711153,-3.45298246 52.538728,-3.4522807 68.1217599,12.0831579 C83.7061995,27.6214035 83.7047918,52.8087719 68.1217599,68.3463158 C52.5380241,83.8838596 27.2732269,83.8852632 11.6887872,68.3477193 Z M38.8588264,45.0983158 C38.8588264,45.0983158 46.0411408,44.086386 48.1161567,40.0884912 C50.1925804,36.0934035 52.6378333,27.9951579 52.6378333,27.9951579 C41.5792934,27.9944561 40.593872,31.8569123 40.593872,31.8569123 C40.593872,31.8569123 33.6044187,51.3411228 31.1120064,58.5298947 C11.746364,58.5298947 14.8412911,48.9930526 14.8412911,48.9930526 L24.5279836,21.9011228 L44.1533549,21.9011228 L42.8427444,25.8028772 C42.8427444,25.8028772 44.4419426,21.9011228 55.2583503,21.9011228 C55.2583503,21.9011228 66.3471567,21.9495439 65.0442888,25.8232281 C63.7435326,29.6955088 59.5604187,41.3123509 59.5604187,41.3123509 C58.1611203,45.0983158 49.97438,45.0653333 38.8588264,45.0983158 Z"></path>
                    </g>
                  </g>
                </svg>
              </div>
              
              <Typography variant="h3" gutterBottom>
                🎉 Congratulations! 🎉
              </Typography>
              
              <Typography variant="h5" className={classes.message}>
                You have successfully completed the Backstage Techlab!
              </Typography>    <Route path="/" element={<HomePage />} />
              
              <Typography variant="body1" className={classes.message}>
                You've learned how to set up, customize, and extend Backstage to create
                an amazing developer portal. Keep exploring and building!
              </Typography>
            </Box>
          </Grid>
        </Grid>
      </Content>
    </Page>
  );
};
```

Update the Sidebar navigation entries:
```typescript
# In packages/app/src/components/root/Root.tsx
  <SidebarItem icon={HomeIcon} to="/" text="Home" />
  <SidebarItem icon={CatalogIcon} to="catalog" text="Catalog" />
```

Set the route element in `App.tsx`:
```typescript
    <Route path="/" element={<HomePage />} />
```

{{% onlyWhen fullScope %}}


## Task {{% param sectionnumber %}}.5: Configure Plugin Permissions

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
