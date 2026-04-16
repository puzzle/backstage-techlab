---
title: "5.3.1 Fill the Catalog with Processors"
weight: 531
sectionnumber: 5.3.1
---

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
