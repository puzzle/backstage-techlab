---
title: "9. Your First Backstage Contribution"
weight: 9
sectionnumber: 9
---

Backstage is an open-source project hosted on GitHub and maintained by a large community of contributors. This lab guides you through your first contribution — from finding a good issue to submitting a pull request — based on the official [ContribFest guide](https://contribfest.backstage.io/getting-started/).

There are two repositories you can contribute to:

| Repository | What lives here |
| --- | --- |
| [backstage/backstage](https://github.com/backstage/backstage) | Core framework, plugins shipped with the main repo |
| [backstage/community-plugins](https://github.com/backstage/community-plugins) | Community-maintained plugins |


## Prerequisites

* A GitHub account that can fork public repositories
* Node.js 22.x and Yarn already set up (see [Lab 1](../../01/))
* `git` configured with your name and email:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```


## Task {{% param sectionnumber %}}.1: Configure Commit Sign-off (DCO)

Backstage requires every commit to be signed off under the [Developer Certificate of Origin (DCO)](https://developercertificate.org/). This is a lightweight statement that you have the right to contribute the code.

The sign-off is added automatically by passing `-s` to `git commit`:

```bash
git commit -s -m "fix: correct typo in catalog README"
```

This appends the following line to your commit message:

```
Signed-off-by: Your Name <you@example.com>
```

**Automate it in VS Code**: add the following to your VS Code settings to never forget it:

```json
"git.alwaysSignOff": true
```

{{% alert title="Warning" color="secondary" %}}
Pull requests where commits are missing the sign-off will fail the DCO check and cannot be merged. If you forget, you can amend the last commit with `git commit --amend -s`.
{{% /alert %}}


## Task {{% param sectionnumber %}}.2: Fork and Clone the Repository


### Step 1: Fork

Go to the repository you want to contribute to and create your own fork:

* Backstage core: [github.com/backstage/backstage/fork](https://github.com/backstage/backstage/fork)
* Community plugins: [github.com/backstage/community-plugins/fork](https://github.com/backstage/community-plugins/fork)


### Step 2: Clone your fork

Use `--filter=tree:0` to avoid downloading the full Git history (the Backstage repository is very large):

```bash
git clone --filter=tree:0 https://github.com/{your-username}/backstage
cd backstage
```


### Step 3: Install dependencies

```bash
yarn install
```

This will take a few minutes on the first run.


## Task {{% param sectionnumber %}}.3: Find a Good First Issue

The Backstage community labels beginner-friendly issues with `good first issue`. The [ContribFest issues page](https://contribfest.backstage.io/issues/) lists curated issues across both repositories.

Alternatively, browse directly on GitHub:

* [backstage/backstage good first issues](https://github.com/backstage/backstage/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)
* [backstage/community-plugins good first issues](https://github.com/backstage/community-plugins/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)

Good issue types for a first contribution:

* **Documentation fixes**: Typos, outdated instructions, missing examples
* **TypeScript type improvements**: Adding missing types or fixing `any`
* **Test coverage**: Adding tests for uncovered code paths
* **Small bug fixes**: Issues labelled with both `good first issue` and `bug`

{{% alert title="Tip" color="primary" %}}
Leave a comment on the issue saying you are working on it. This prevents duplicate work and opens a channel for questions with the maintainers.
{{% /alert %}}


## Task {{% param sectionnumber %}}.4: Make Your Change


### Step 1: Create a branch

Always work on a dedicated branch, not `main`:

```bash
git checkout -b fix/my-first-contribution
```

Use a descriptive branch name that reflects the change (e.g., `docs/fix-catalog-typo`, `fix/search-null-pointer`).


### Step 2: Make the change

Edit the relevant files. A few helpful commands while working:

```bash
# Type-check the whole codebase
yarn tsc

# Run tests for a specific package
yarn jest packages/catalog-client --watch

# Format a file
yarn prettier --write path/to/file.ts
```


### Step 3: Verify your change locally

For frontend changes, start the development app:

```bash
yarn start
```

For backend changes or plugin work, follow the README in the affected package directory.


## Task {{% param sectionnumber %}}.5: Create a Changeset

If your change affects a published package (anything under `packages/` or `plugins/`), you must add a **changeset**. A changeset describes the change for the release notes.

```bash
yarn changeset
```

The CLI will ask you:

1. Which packages are affected (use arrow keys + space to select)
2. The bump type: `patch` (bug fix), `minor` (new feature), `major` (breaking change)
3. A short human-readable description of the change

This creates a `.changeset/*.md` file — commit it together with your code changes.

{{% alert title="Note" color="primary" %}}
Documentation-only changes and test-only changes typically do not require a changeset. If unsure, check the existing PR descriptions for similar changes or ask in the issue comments.
{{% /alert %}}


## Task {{% param sectionnumber %}}.6: Open a Pull Request


### Step 1: Push your branch

```bash
git push origin fix/my-first-contribution
```


### Step 2: Open the PR on GitHub

Go to your fork on GitHub. GitHub will show a prompt to open a pull request for your recently pushed branch. Click **Compare & pull request**.

Fill in the PR template:

* **Title**: Use the conventional commit format, e.g., `fix(catalog): correct null check in entity processor`
* **Description**: Explain what the issue is, what you changed, and why
* **Screenshots**: Include before/after screenshots for any UI changes
* **Checklist**: Complete all items in the PR template


### Step 3: Respond to review feedback

Maintainers will review your PR and may request changes. Update your branch, push again, and the PR will update automatically. You do not need to open a new PR.

```bash
# Make requested changes, then:
git add .
git commit -s -m "fix: address review feedback"
git push origin fix/my-first-contribution
```


## Summary

In this chapter, you:

* Configured DCO commit sign-off
* Forked and cloned a Backstage repository
* Found a beginner-friendly issue
* Created a branch, made a change, and verified it locally
* Added a changeset for the release notes
* Submitted a pull request

Contributing to Backstage is a great way to deepen your understanding of the framework while helping the entire community. The maintainers are welcoming and the [Discord community](https://discord.gg/backstage-687207715902193673) is an excellent place to ask questions.


## Resources

* [ContribFest Getting Started](https://contribfest.backstage.io/getting-started/)
* [Backstage CONTRIBUTING.md](https://github.com/backstage/backstage/blob/master/CONTRIBUTING.md)
* [Community Plugins CONTRIBUTING.md](https://github.com/backstage/community-plugins/blob/main/CONTRIBUTING.md)
* [Backstage Discord](https://discord.gg/backstage-687207715902193673)
* [Curated good-first issues](https://contribfest.backstage.io/issues/)
