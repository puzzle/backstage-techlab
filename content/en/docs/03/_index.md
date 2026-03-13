---
title: "3. Using Software Templates"
weight: 3
sectionnumber: 3
---

Software Templates in Backstage enable self-service for developers. Instead of copying boilerplate code or following lengthy setup guides, developers can use templates to scaffold new projects with best practices built in. This chapter will teach you how to create and use templates effectively.


## Understanding Software Templates

Software Templates (also called Scaffolder Templates) allow you to:

* **Standardize project setup**: Ensure all projects follow organizational best practices
* **Reduce onboarding time**: New developers can create production-ready projects in minutes
* **Enforce compliance**: Build in security, monitoring, and governance from day one
* **Accelerate development**: Eliminate repetitive setup tasks

{{% alert title="Note" color="primary" %}}
Templates use a declarative YAML format and can integrate with Git providers, CI/CD systems, and other tools to fully automate project creation.
{{% /alert %}}


## Task {{% param sectionnumber %}}.1: Explore Existing Templates

Before creating your own template, let's explore what's available by default.
To make the following tasks work you need a GitHub Personal Access Token with the appropriate scopes.


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


### Step 2: Set the environment variable

Set the `GITHUB_TOKEN` environment variable with your token:

```bash
export GITHUB_TOKEN=ghp_your_token_here
```

**Alternative: Use app-config.local.yaml (not recommended for production)**

For local development only, you can create an `app-config.local.yaml` file (which should be in `.gitignore`):

```yaml
integrations:
  github:
    - host: github.com
      token: ghp_your_token_here
```

{{% alert title="Warning" color="warning" %}}
Never commit tokens directly to your repository! Always use environment variables or secret management tools in production.
{{% /alert %}}


### Step 3: Run the default template

1. Navigate to `http://localhost:3000/create`
2. Click on `choose` to select the example template
3. Set the `Name`, your `GitHub-Username` and the `name for the new repository`
4. Create it

See the created component via `Open in Catalog`!

![Template Result](/docs/03/default_template.png)


## Task {{% param sectionnumber %}}.2: Create a Template with Multiple Steps

Let's create a more sophisticated template that includes CI/CD setup and demonstrates advanced features like multiple parameter sections, conditional logic, and multiple fetch steps.


### Step 1: Download the advanced template files

Download the full-stack application template from the [Template Data](https://github.com/StephGit/backstage-techlab-data) repository.

Create a new directory for the advanced template and add the files there:

```bash
mkdir -p ./backstage-data/templates/fullstack-app
...
ls ./backstage-data/templates/fullstack-app
fullstack-app
```

<details>
  <summary>Analyse the advanced template.yaml</summary>

```yaml
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: fullstack-app
  title: Full-Stack Application
  description: Create a complete full-stack application with React frontend, Node.js backend, and CI/CD
  tags:
    - recommended
    - fullstack
    - react
    - nodejs
spec:
  owner: team-a
  type: website
  
  parameters:
    - title: Application Information
      required:
        - name
        - description
      properties:
        name:
          title: Application Name
          type: string
          description: Unique name for the application
        description:
          title: Description
          type: string
          description: What does this application do?
        owner:
          title: Owner
          type: string
          ui:field: OwnerPicker
          ui:options:
            catalogFilter:
              kind: Group
    
    - title: Technology Choices
      properties:
        database:
          title: Database
          type: string
          description: Which database to use?
          enum:
            - postgresql
            - mysql
            - mongodb
          default: postgresql
        includeAuth:
          title: Include Authentication
          type: boolean
          description: Add authentication scaffolding?
          default: true
    
    - title: Repository Information
      required:
        - repoUrl
      properties:
        repoUrl:
          title: Repository Location
          type: string
          ui:field: RepoUrlPicker
          ui:options:
            allowedHosts:
              - github.com

  steps:
    - id: fetch-base
      name: Fetch Base Template
      action: fetch:template
      input:
        url: ./skeleton
        values:
          name: ${{ parameters.name }}
          description: ${{ parameters.description }}
          owner: ${{ parameters.owner }}
          database: ${{ parameters.database }}
          includeAuth: ${{ parameters.includeAuth }}

    - id: fetch-docs
      name: Fetch Documentation
      action: fetch:plain
      input:
        url: ./docs
        targetPath: ./docs

    - id: publish
      name: Publish to GitHub
      action: publish:github
      input:
        allowedHosts: ['github.com']
        description: ${{ parameters.description }}
        repoUrl: ${{ parameters.repoUrl }}
        defaultBranch: main
        repoVisibility: private
        deleteBranchOnMerge: true
        protectDefaultBranch: false

    - id: create-github-actions
      name: Create GitHub Actions Workflow
      action: fetch:template
      input:
        url: ./workflows
        targetPath: .github/workflows
        values:
          name: ${{ parameters.name }}

    - id: register
      name: Register Component
      action: catalog:register
      input:
        repoContentsUrl: ${{ steps.publish.output.repoContentsUrl }}
        catalogInfoPath: '/catalog-info.yaml'

  output:
    links:
      - title: Repository
        url: ${{ steps.publish.output.remoteUrl }}
      - title: Open in Catalog
        icon: catalog
        entityRef: ${{ steps.register.output.entityRef }}
      - title: CI/CD Pipeline
        url: ${{ steps.publish.output.remoteUrl }}/actions
```
</details>

**Key features of this template:**

* **Multiple parameter sections**: Organized form with different categories (Application Info, Technology Choices, Repository)
* **Conditional logic**: Options like `includeAuth` and `database` that affect generated code
* **Multiple fetch steps**: Combines skeleton files, documentation, and workflow files
* **CI/CD integration**: Automatically creates GitHub Actions workflows

**Analyse the skeleton structure:**

The skeleton folder contains a more complex structure:

* `frontend/` - React application with routing and state management
* `backend/` - Node.js API with database integration
* `docs/` - Documentation files
* `.github/workflows/` - CI/CD pipeline configuration
* `docker-compose.yml` - Local development environment
* Conditional files based on `${{ values.includeAuth }}` and `${{ values.database }}`


### Step 2: Register the template

Add the template location to your `app-config.yaml`:

```yaml
catalog:
  locations:
    - type: file
      target: ../../backstage-data/templates/fullstack-app/template.yaml
      rules:
        - allow: [Template]
```

Wait for the catalog to refresh and navigate to `http://localhost:3000/create` to see your advanced template!


### Step 3: Test the template

1. Click on "Full-Stack Application"
2. Fill in the form and experiment with different options:
   * Try different database choices (PostgreSQL, MySQL, MongoDB)
   * Toggle the authentication option
3. Create the application and explore the generated repository

Notice how the template adapts based on your selections!

{{% onlyWhen fullScope %}}


## Task {{% param sectionnumber %}}.5: Add Custom Template Actions

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


## Common Template Use Cases

Here are some popular template use cases:

* **Microservices**: Standard service template with logging, metrics, and health checks
* **Frontend applications**: React/Vue/Angular apps with routing and state management
* **Documentation sites**: TechDocs-enabled documentation repositories
* **Infrastructure**: Terraform modules or Kubernetes manifests
* **Libraries**: Shared code libraries with publishing pipelines
* **Data pipelines**: ETL jobs with scheduling and monitoring


## Summary

In this chapter, you:

* ✅ Explored existing Backstage templates
* ✅ Created your first software template
* ✅ Built a template skeleton with variables
* ✅ Registered and used your template

Software Templates are one of Backstage's most powerful features for improving developer productivity. By standardizing project creation, you reduce cognitive load and ensure consistency across your organization.  
