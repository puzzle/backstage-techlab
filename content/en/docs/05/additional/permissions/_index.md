---
title: "5.3.3 Introduction to Plugin usage"
weight: 533
sectionnumber: 5.3.3
---

## Task {{% param sectionnumber %}}.1: Configure Plugin Permissions

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


## Summary

In this chapter, you:

* ✅ Learned how to configure fine-grained permissions
