---
title: "3.2.1 GitHub Integration"
weight: 321
sectionnumber: 3.2.1
---


## Prerequisites

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

TODO CRA: as less rights als possible! -> SGI: that's it :-)


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


## Task {{% param sectionnumber %}}.1: Explore Existing Templates

Before creating your own template, let's explore what's available by default.


### Run the default template
