---
title: "10. AI-Assisted Backstage Development"
weight: 10
sectionnumber: 10
---

Modern AI coding assistants like [Claude Code](https://claude.ai/code), GitHub Copilot, or Cursor can significantly accelerate Backstage development. However, the Backstage monorepo has specific conventions, commands, and restrictions that an AI assistant must know to be useful rather than harmful.

The Backstage project ships an [`AGENTS.md`](https://github.com/backstage/backstage/blob/master/AGENTS.md) file at the repository root. This file is the authoritative guide for AI agents working in the codebase. Claude Code and other AI tools automatically pick up this file when working inside the repository, giving the assistant project-specific context without any manual prompting.

This lab shows you how to work effectively with an AI coding assistant on Backstage development tasks.


## What AGENTS.md Provides

The `AGENTS.md` file gives an AI assistant the following context:

| Area | Guidance |
| --- | --- |
| **Directory structure** | Where core packages, plugins, and example apps live; what naming prefixes mean |
| **Key reference files** | `CONTRIBUTING.md`, `STYLE.md`, `REVIEWING.md`, `SECURITY.md` |
| **Development commands** | Which commands to run and — critically — which ones to **never** run |
| **Testing conventions** | How to write and run tests, preferred React Testing Library patterns |
| **Changeset requirements** | When and how to create changesets, what audience to write them for |
| **Code consistency** | Package-level consistency takes priority over monorepo-wide uniformity |

{{% alert title="Note" color="primary" %}}
`AGENTS.md` is the AI-specific counterpart to `CONTRIBUTING.md`. It is written to be consumed by an AI agent rather than a human, using precise, unambiguous instructions that reduce the chance of the assistant doing something destructive.
{{% /alert %}}


## Task {{% param sectionnumber %}}.1: Set Up Claude Code in the Backstage Repository


### Step 1: Open the repository in your terminal

If you completed [Lab 9](../../09/), you already have a local Backstage fork. Navigate to it:

```bash
cd backstage
```


### Step 2: Start Claude Code

```bash
claude
```

Claude Code reads `AGENTS.md` automatically on startup. You can verify this by asking:

> "What commands should I never run in this repository?"

The assistant should answer based on the `AGENTS.md` content: never run `yarn build`, `yarn changesets version`, or `yarn release`.


### Step 3: Explore the project context

Ask Claude Code to orient itself:

> "Summarize the structure of this repository and tell me where I should look if I want to add a new frontend plugin."

A well-configured assistant will describe the `/plugins` directory, the `@backstage/plugin-*` naming convention, and point you to `CONTRIBUTING.md`.


## Task {{% param sectionnumber %}}.2: Use AI to Navigate the Codebase

The Backstage monorepo contains hundreds of packages. AI assistants excel at answering structural questions that would otherwise require minutes of manual searching.

Try the following prompts in Claude Code:

**Understanding a package:**
> "Explain what `@backstage/plugin-catalog-backend` does and list its main exported classes."

**Finding the right place for a change:**
> "I want to add a new field to the catalog entity metadata. Which packages are involved and what files would I need to change?"

**Understanding patterns:**
> "Show me an example of how a backend plugin registers a route in the new Backend System."

{{% alert title="Tip" color="primary" %}}
Claude Code can read files directly from the repository. Use precise questions referencing specific packages or files to get the most accurate answers.
{{% /alert %}}


## Task {{% param sectionnumber %}}.3: Let AI Assist with a Code Change

Use Claude Code to implement a small, safe change — for example, adding a utility function or improving type safety in an existing file.


### Example prompt flow

**Step 1 — Define the task clearly:**

> "In `packages/catalog-client/src/CatalogClient.ts`, the `getEntityByRef` method returns `Entity | undefined`. Add a helper function `isEntityRef` that validates whether a string is a valid entity reference format (`kind:namespace/name`)."

**Step 2 — Review the proposed change:**

Claude Code will show you the diff before applying it. Always read the diff carefully:

* Does the change match what you asked for?
* Are there any unintended modifications to other files?
* Does the code follow the existing patterns in the file?

**Step 3 — Run the checks:**

```bash
# Type-check
yarn tsc

# Run tests for the affected package
CI=1 yarn test packages/catalog-client

# Lint and format
yarn lint packages/catalog-client
yarn prettier --write packages/catalog-client/src/CatalogClient.ts
```

**Step 4 — Create a changeset if needed:**

If the change affects a published package, create a changeset. The `AGENTS.md` explicitly instructs AI agents to write changesets directly as files rather than using the CLI:

```bash
# Create the file directly (do not use `yarn changeset`)
cat > .changeset/your-change-description.md << 'EOF'
---
"@backstage/catalog-client": patch
---

Added `isEntityRef` helper to validate entity reference strings.
EOF
```


## Task {{% param sectionnumber %}}.4: Know the Limits and Guardrails

AI assistants are powerful but must be supervised when working in a large codebase like Backstage. The `AGENTS.md` defines explicit restrictions:


### Commands to never run

| Command | Why it is forbidden |
| --- | --- |
| `yarn build` | Builds the entire monorepo — slow, not needed during development |
| `yarn changesets version` | Bumps all package versions — only run by automated release pipelines |
| `yarn release` | Publishes packages to npm — only run by CI |


### Config files to never modify

Unless you explicitly ask, the assistant must not touch:

* ESLint configuration
* Prettier configuration
* TypeScript configuration (`tsconfig.json` files)


### AI tool guidelines from CONTRIBUTING.md

The Backstage project has specific expectations for AI-assisted contributions:

* You must understand and be able to explain every change you submit
* Do not submit AI-generated PR descriptions without personal review
* Clearly mark largely AI-generated work in the PR
* Use AI for code generation; write the PR description yourself

{{% alert title="Warning" color="secondary" %}}
Do not blindly apply AI suggestions. The monorepo has subtle inter-package dependencies. A change that looks correct in isolation may break API compatibility or violate package boundaries. Always run `yarn tsc` to catch type errors across packages.
{{% /alert %}}


## Task {{% param sectionnumber %}}.5: Use AI for Writing Tests

Writing tests for existing code is one of the safest and most productive uses of an AI assistant in a new codebase.

> "Write unit tests for the `isEntityRef` function we added earlier. Follow the existing test patterns in `packages/catalog-client/src/CatalogClient.test.ts`."

Key conventions from `AGENTS.md` to verify in the generated tests:

* **Fewer comprehensive tests** with multiple assertions, not many minimal single-assertion tests
* **React Testing Library**: use `screen` and `.findBy*` queries, not `waitFor`
* **No test IDs added to implementation code**: tests should query by role, label, or text

Run the tests to verify:

```bash
CI=1 yarn test packages/catalog-client
```


## Summary

In this chapter, you:

* Understood the purpose of `AGENTS.md` and how Claude Code uses it
* Set up Claude Code inside the Backstage repository
* Used AI to navigate the codebase and understand package structure
* Made a code change with AI assistance and verified it with `yarn tsc` and tests
* Learned the commands and files that must never be touched by an AI agent
* Used AI to generate well-structured tests following Backstage conventions

AI coding assistants are most effective when they have project-specific context (`AGENTS.md`), when you review every diff before applying it, and when you run the standard verification commands after each change.


## Next Steps

Now that you've completed this lab, you could add an `AGENTS.md` to your own Backstage instance.

Such that you and your team can use AI coding assistants to develop your portal.
