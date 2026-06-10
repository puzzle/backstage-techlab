---
title: "5.3.2 Use the GitHub Actions Plugin"
weight: 532
sectionnumber: 5.3.2
---


## Task {{% param sectionnumber %}}.3: Install the GitHub Actions Plugin

Let's add CI/CD visibility with the GitHub Actions plugin.


### Step 1: Install and configure the plugin

```bash
# From your Backstage root directory
yarn --cwd packages/app add @backstage-community/plugin-github-actions
```

Import `githubActionsPlugin` in your `packages/app/src/App.tsx` and add it to your app's `features` array:

```typescript
import githubActionsPlugin from '@backstage-community/plugin-github-actions/alpha';

// ...

export const app = createApp({
  features: [ ... githubActionsPlugin, ],
});
```

Enable the GitHub auth provider in the backend, edit `packages/backend/src/index.ts`:

```bash
backend.add(import('@backstage/plugin-auth-backend-module-github-provider'));
```


### Step 2: Register a GitHub OAuth app

To enable integration with GitHub, you need to register a GitHub OAuth app. This enables Backstage to authenticate users and access GitHub repositories on their behalf.

1. Go to GitHub Settings: [https://github.com/settings/developers](https://github.com/settings/developers)
2. Click **"New OAuth App"**
3. Fill in the form:
   * **Application name**: Backstage
   * **Homepage URL**: http://localhost:3000
   * **Authorization callback URL**: http://localhost:7007/api/auth/github/handler/frame
4. Click **"Register application"** and **"Generate a new client secret"**
5. Note the **Client ID** and **Client Secret**


Add the following to your `app-config.local.yaml`:

```yaml
auth:
  providers:
    ...
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
