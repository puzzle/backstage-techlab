---
title: "3.2.1 GitHub Integration"
weight: 321
sectionnumber: 3.2.1
---

We will set up the Integration into GitHub such that your Backstage App can read Software Templates and push generated applications.


## Task {{% param sectionnumber %}}.1: Create a GitHub Integration


### Prerequisites

To make the following tasks work you need a personal GitHub where you can create Personal Access Tokens.


### Step 1: Create a GitHub Personal Access Token

To allow Backstage to access your GitHub repositories, you need to create a Personal Access Token (PAT):

1. Go to GitHub Settings: [https://github.com/settings/tokens](https://github.com/settings/tokens)
2. Click **"Generate new token"** → **"Generate new token (classic)"**
3. Give your token a descriptive name (e.g., "Backstage Catalog Discovery")
4. Select the following scopes:
   * `repo` (Full control of private and public repositories) - access private and public repos
   * `workflow` (Access GitHub Actions workflows) - to update workflows
   * `write:org` (Write org projects) - to write a new repo
   * `read:org` (Read org and team membership) - to read organization data
   * `read:user` (Read user profile data)
5. Click **"Generate token"**
6. **Copy the token immediately** - you won't be able to see it again!

{{% alert title="Important" color="warning" %}}
Be better than Trivy. Do not let your token get caught! See [CVE-2026-33634](https://nvd.nist.gov/vuln/detail/CVE-2026-33634) for details.
{{% /alert %}}


### Step 2: Configure your Backstage

Your configuration (`app-config.yaml`) is already prepared for GitHub Integrations:

```yaml
integrations:
  github:
    - host: github.com
      # This is a Personal Access Token or PAT from GitHub. You can find out how to generate this token, and more information
      # about setting up the GitHub integration here: https://backstage.io/docs/integrations/github/locations#configuration
      token: ${GITHUB_TOKEN}
```

We notice, that it will be activated when the environment variable `GITHUB_TOKEN` is present.

Set the `GITHUB_TOKEN` environment variable with your token (replace the `ghp_your_token_here` value):

```bash
export GITHUB_TOKEN=ghp_your_token_here
```

**Alternative: Use app-config.local.yaml (not recommended at all!)**

For local development only, you could create an `app-config.local.yaml` file (which should be in `.gitignore`).

This file will extend the configuration of your `app-config.yaml`. This is a default behavior of Backstage ([documentation](https://backstage.io/docs/conf/)).

Add following content to your  `app-config.local.yaml` file with replaced `ghp_your_token_here` value:

```yaml
integrations:
  github:
    - host: github.com
      token: ghp_your_token_here
```

{{% alert title="Warning" color="warning" %}}
Never commit tokens directly to your repository! Always use environment variables or secret management tools in production.

Prevent also coding agents from getting your token!
{{% /alert %}}


### Step 2: Do lab 3.1.1 again

Run the template task again: [Explore Existing Templates](../../3.1/#task-311-explore-existing-templates)

But this time, set the right values for `Name`, `Owner` and `Repository`.
Most important is your GitHub user name for `Owner`.

Now you should see a successful template run.

![Template Result](/docs/03/additional/github/scaffolded.png)

1. Click on the `REPOSITORY` link to get to your generated app on GitHub.
2. Check that your input values are present inside `catalog-info.yaml`.
3. Click on the `OPEN IN CATALOG` link to find your new application in the Backstage catalog.
4. Is the same user/group visible in the relations that you selected in the template?


## Task {{% param sectionnumber %}}.2: Create a Template with Multiple Steps

Run the template task again: [Create a Template with Multiple Steps](../../3.1/#task-312-create-a-template-with-multiple-steps)


But this time, set the right values for `Name`, `Owner` and `Repository`.
Most important is your GitHub user name for `Owner`.

Now you should see a successful template run.


1. Click on the `REPOSITORY` link to get to your generated app on GitHub.
2. Check that your input values are present inside `catalog-info.yaml`.
3. Click on the `OPEN IN CATALOG` link to find your new application in the Backstage catalog.
4. Is the same user/group visible in the relations that you selected in the template?
5. Click on the `CI/CD PIPELINE` link to find your new applications actions.

<!-- TODO CRA: fix actions link -->
<!-- TODO CRA: fix workflow folder name -->

Notice how the template adapts based on your selections!


{{% onlyWhen fullScope %}}
<!-- TODO CRA: enablen? -->


## Task {{% param sectionnumber %}}.3: Add Custom Template Actions

Backstage allows you to create custom actions for templates. Here's an example of how to add a custom action to send a Slack notification.

In your Backstage backend, you can register custom actions. Create a file `packages/backend/src/plugins/scaffolder.ts`:

```typescript
import { CatalogClient } from '@backstage/catalog-client';
import { createRouter, createBuiltinActions } from '@backstage/plugin-scaffolder-backend';
import { Router } from 'express';
import type { PluginEnvironment } from '../types';
import { ScmIntegrations } from '@backstage/integration';
import { createSlackNotificationAction } from './scaffolder/actions/slack';

export default async function createPlugin(
  env: PluginEnvironment,
): Promise<Router> {
  const catalogClient = new CatalogClient({
    discoveryApi: env.discovery,
  });

  const integrations = ScmIntegrations.fromConfig(env.config);
  const builtInActions = createBuiltinActions({
    integrations,
    catalogClient,
    config: env.config,
    reader: env.reader,
  });

  const actions = [
    ...builtInActions,
    createSlackNotificationAction(),
  ];

  return await createRouter({
    actions,
    logger: env.logger,
    config: env.config,
    database: env.database,
    reader: env.reader,
    catalogClient,
  });
}
```

{{% alert title="Note" color="primary" %}}
Custom actions allow you to integrate templates with any external system - from cloud providers to internal tools.
{{% /alert %}}

{{% /onlyWhen %}}


## Summary

In this chapter, you:

* ✅ Connected your Backstage instance with GitHub
* ✅ Really created your first software template and pushed it to GitHub
* ✅ Got a glimpse of what is possible to realize with software templates
