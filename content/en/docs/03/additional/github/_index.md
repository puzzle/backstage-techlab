---
title: "3.2.1 GitHub Integration"
weight: 321
sectionnumber: 3.2.1
---

We will set up the Integration into GitHub such that your Backstage App can read Software Templates and push generated applications.


## Prerequisites

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
Be better than Trivy. Do not let your token get caught!
{{% /alert %}}


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

Prevent also coding agents from getting your token!
{{% /alert %}}


### Step 2: Do lab 3 again

Run the template task again: [Explore Existing Templates](../../3.1/)

But this time, set the right values for `Name`, `Owner` and `Repository`.
Most important is your GitHub user name for `Owner`.


### Run the default template
