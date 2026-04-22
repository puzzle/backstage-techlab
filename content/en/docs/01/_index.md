---
title: "1. Local Setup, Development and Testing"
weight: 1
sectionnumber: 1
---

In this chapter, you will set up your local Backstage environment, learn how to start the application in development mode, and explore its core features.

This hands-on introduction will give you the foundation needed to customize and extend Backstage for your organization.


## Prerequisites

Before you begin, ensure you have the following installed on your local machine:

* **Node.js**: Version 22 or 24 (Recommendation: nvm or volta)
* **Package Manager**: Yarn
* **Source Control**: Git
* **Container**: Docker or Podman

{{% alert title="Note" color="primary" %}}
You can verify your Node.js version with `node --version`. If you need to install or update Node.js, we recommend using [nvm](https://github.com/nvm-sh/nvm) or [volta](https://volta.sh/) for easy version management.
{{% /alert %}}


## Task {{% param sectionnumber %}}.1: Create a New Backstage App

Backstage provides a CLI tool to scaffold a new application quickly. Let's create your first Backstage instance.

First create a folder for the techlab inside your workspaces folder or in a temporary directory.

Run the following command to create a new Backstage app:

```bash
npx -y @backstage/create-app@0.8.2
```

When prompted, enter a name for your app (**`my-backstage-app`**).

{{% alert title="Note" color="primary" %}}
The creation process may take several minutes as it downloads dependencies and sets up the project structure.
{{% /alert %}}

The output should look similar to:

```bash  
  ...
  copying       index.ts ✔ 

 Moving to final location:
  moving        my-backstage-app ✔ 
  fetching      yarn.lock seed ✔ 
  init          git repository ◜ 
 Installing dependencies:
  init          git repository ✔ 
  executing     yarn install ✔ 
  executing     yarn tsc ✔ 

🥇  Successfully created my-backstage-app


 All set! Now you might want to:
  Run the app: cd my-backstage-app && yarn start
  Set up the software catalog: https://backstage.io/docs/features/software-catalog/configuration
  Add authentication: https://backstage.io/docs/auth/
```

After the creation process is complete, navigate into your newly created app directory.

```bash
cd my-backstage-app
```

Explore the project structure. You should see:

* `packages/app/` - Frontend React application
* `packages/backend/` - Backend Node.js application
* `app-config.yaml` - Main configuration file
* `catalog-info.yaml` - Catalog entity for the Backstage app itself (will be explained later)


## Task {{% param sectionnumber %}}.2: Start Backstage in Development Mode

Now let's start Backstage locally to see it in action.

Start both the frontend and backend in development mode:

```bash
yarn start
```

This command will:

* Start the backend on `http://localhost:7007`
* Start the frontend on `http://localhost:3000`
* Enable hot-reloading for development

If your browser did not open a tab, navigate to `http://localhost:3000`

This should show the home page of your newly created Backstage application!

![Backstage Homepage](/docs/01/homepage.png)

Click on the `ENTER` button.


You may see a warning message like:

```
You are currently using the legacy guest token...
```

{{% alert title="Note" color="primary" %}}
This warning is expected for local development. Backstage uses a guest authentication mode by default, which is fine for development purposes. In production, you would configure proper authentication (OAuth, SAML, etc.).

You can safely ignore this warning for now.
{{% /alert %}}


### Task {{% param sectionnumber %}}.2.1: Explore the Default Interface

The default installation includes example entities to help you understand how Backstage organizes information.

Take a few minutes to explore the default Backstage interface.

Use the Left-Side vertical navigation to check out your Backstage instance with it's example content:

1. **Home (Catalog)**: The landing page and the catalog main page
2. **APIs**: Check out the APIs section
3. **Docs**: Explore the TechDocs section
4. **Create**: Look at the "Create" section (we'll use this later for templates)
5. **Search**: Try to search for any content

Now you should have a first insight of the basic Backstage functionality.


## Task {{% param sectionnumber %}}.3: Understand the Configuration

Open the `app-config.yaml` file in your editor. This is the heart of your Backstage configuration.

Key sections to note:

```yaml
app:
  title: Scaffolded Backstage App #(1)
  baseUrl: http://localhost:3000

organization:
  name: My Company #(2)

backend:
  baseUrl: http://localhost:7007 #(3)
  listen:
    port: 7007
  
catalog: #(4)
  import:
    entityFilename: catalog-info.yaml
  rules:
    - allow: [Component, System, API, Resource, Location, Group, User]
```

**Explanation:**

1. `app.title`: The name displayed in the browser tab
2. `organization.name`: Your company / organization name displayed in the UI.
3. `backend.baseUrl`: Where the backend API is running
4. `catalog`: Configuration for the software catalog


### Task {{% param sectionnumber %}}.3.1: Customize Your Backstage Instance

Let's make a simple customization to make this instance your own.

Edit `app-config.yaml` and change the organization name:

```yaml
organization:
  name: Your Company Name
```

Also update the app title:

```yaml
app:
  title: Your Company Developer Portal
```

Save the file.

Thanks to hot-reloading, you should see the changes reflected in your browser within seconds!


## Task {{% param sectionnumber %}}.4: Run Tests


### Unit Tests

Backstage comes with a [jest](https://jestjs.io/) testing setup out of the box.

{{% alert title="Note" color="primary" %}}
Run the tests in a new terminal inside the `backstage-techlab` folder or stop your Backstage by pressing `CTRL+c` on your keyboard.
{{% /alert %}}

Start the test suite:

```bash
yarn test
```

You should see a list with all available options.

```bash
No tests found related to files changed since last commit.
Press `a` to run all tests, or run Jest with `--watchAll`.

Watch Usage
 › Press a to run all tests.
 › Press f to run only failed tests.
 › Press p to filter by a filename regex pattern.
 › Press t to filter by a test name regex pattern.
 › Press q to quit watch mode.
 › Press Enter to trigger a test run.
```

Press `a` to run all tests and see, that all pass.

```bash
 PASS   app  packages/app/src/App.test.tsx
  App
    ✓ should render (33 ms)

Test Suites: 1 passed, 1 total
Tests:       1 passed, 1 total
Snapshots:   0 total
Time:        2.822 s, estimated 6 s
Ran all test suites.
```

For the moment there's just a basic test to check that the setup is working.

{{% alert title="Note" color="primary" %}}
Press `q` on your keyboard to exit the test suite.
{{% /alert %}}


To check the test coverage run:

```bash
yarn test:all
```

You will notice, that there are some lines of code not covered by any tests.


### E2E Tests

For end-to-end tests a [playwright](https://playwright.dev/) setup is ready to use.

It will start your Backstage instance and run the tests against it.

```bash
yarn test:e2e
```

{{% alert title="Note" color="primary" %}}
Depending on your setup you might get a error running the E2E tests.

You probably need to install browsers first: e.g. `yarn playwright install chrome`
{{% /alert %}}


## Task {{% param sectionnumber %}}.5: Build for Production

While we're developing locally, it's useful to understand how to build Backstage for production.

Create a production build:

```bash
yarn build:all
```

This command performs several build steps:

1. **TypeScript Compilation**: Converts all TypeScript code (`.ts`, `.tsx`) to JavaScript
2. **Frontend Bundling**: Creates an optimized production bundle of the React application
   * Minifies JavaScript and CSS
   * Optimizes assets and images
   * Creates static files ready for deployment
3. **Backend Bundling**: Packages the Node.js backend application
   * Bundles all backend code and dependencies
   * Prepares the backend for deployment
4. **Type Checking**: Validates TypeScript types across the entire codebase

{{% alert title="Note" color="primary" %}}
The production build artifacts are created in the `dist/` directories of each package (`packages/app/dist` and `packages/backend/dist`).

These optimized builds are what you would deploy to production. For this techlab, we won't deploy them, but it's important to understand the build process.
{{% /alert %}}


## Summary

In this chapter, you:

* ✅ Created a new Backstage application
* ✅ Explored the default interface
* ✅ Made your first customization
* ✅ Ran tests and created a production build

Your local Backstage environment is now ready for the next steps!

In the next chapters, you'll learn how to populate the catalog, create templates, and add plugins to make Backstage truly powerful for your organization.
