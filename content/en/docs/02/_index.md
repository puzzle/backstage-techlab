---
title: "2. Setting up the Backstage Catalog"
weight: 2
sectionnumber: 2
---

The Backstage Software Catalog is the heart of your developer portal. It provides a centralized view of all software components, services, APIs, resources, and teams in your organization. In this chapter, you'll learn how to populate and manage the catalog effectively.


## Understanding the Catalog

The catalog uses YAML files to describe entities. Each entity represents something in your software ecosystem:

* **Components**: Individual pieces of software (services, libraries, websites)
* **APIs**: Interfaces that components provide
* **Resources**: Infrastructure resources (databases, queues, storage)
* **Systems**: Collections of components and resources
* **Domains**: Groups of related systems
* **Groups**: Teams or organizational units
* **Users**: Individual people

{{% alert title="Note" color="primary" %}}
The catalog uses a declarative approach - you describe what exists, and Backstage takes care of displaying and organizing it.
{{% /alert %}}


## Task {{% param sectionnumber %}}.1: Create Your First Component

Let's create a simple microservice component and register it in the catalog.

**Create the catalog-info.yaml file

Create a new directory for your sample service folder:

```bash
mkdir -p backstage-data/my-sample-service
```

Create a `catalog-info.yaml` file with the following content:

```yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: my-sample-service
  description: A sample microservice for the Backstage catalog
  annotations:
    github.com/project-slug: your-org/my-sample-service
  tags:
    - nodejs
    - microservice
  links:
    - url: https://dashboard.example.com
      title: Service Dashboard
      icon: dashboard
spec:
  type: service
  lifecycle: production
  owner: team-a
  system: my-system
```

**Understanding the structure:**

* `metadata.name`: Unique identifier for the component
* `metadata.description`: Human-readable description
* `metadata.annotations`: Additional metadata (like GitHub repository)
* `metadata.tags`: Labels for filtering and searching
* `spec.type`: Type of component (service, library, website, etc.)
* `spec.lifecycle`: Stage of development (experimental, production, deprecated)
* `spec.owner`: Team or group that owns this component

See the [Backstage Descriptor Format](https://backstage.io/docs/features/software-catalog/descriptor-format/) for more details.

**Manual registration in the catalog

Add the new entity to the catalog-location in your `app-config.yaml`:

```yaml
catalog:
  locations:
    - type: file
      target: ../../backstage-data/my-sample-service/catalog-info.yaml
      rules:
        - allow: [Component]
```

After restarting, Backstage will automatically pick up the new component.
Navigate to your Backstage catalog and explore the relationships of your component.

Explore the different tabs:

* **Overview**: Basic information
* **Dependencies**: What this component depends on
* **API**: APIs provided by this component
* **Docs**: TechDocs documentation (if configured)

Checkout the entity detail by selecting `Inspect entity` in the submenu in the top right corner.


![Entity Detail](/docs/02/entity-detail.png)


## Task {{% param sectionnumber %}}.2: Create a Complete System

Let's create a more complex example with multiple components forming a system.

Create a new file `catalog-info.yaml` and push it to a github repository:

```yaml
---
apiVersion: backstage.io/v1alpha1
kind: System
metadata:
  name: my-system
  description: An e-commerce platform system
  tags:
    - ecommerce
spec:
  owner: team-a
  domain: retail
---
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: frontend-app
  description: Customer-facing web application
  tags:
    - react
    - frontend
spec:
  type: website
  lifecycle: production
  owner: team-a
  system: my-system
  providesApis:
    - user-api
---
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: backend-api
  description: Backend REST API service
  tags:
    - nodejs
    - api
spec:
  type: service
  lifecycle: production
  owner: team-a
  system: my-system
  providesApis:
    - user-api
    - order-api
  consumesApis:
    - payment-api
---
apiVersion: backstage.io/v1alpha1
kind: API
metadata:
  name: user-api
  description: User management API
spec:
  type: openapi
  lifecycle: production
  owner: team-a
  system: my-system
  definition: |
    openapi: 3.0.0
    info:
      title: User API
      version: 1.0.0
    paths:
      /users:
        get:
          summary: List all users
          responses:
            '200':
              description: Successful response
---
apiVersion: backstage.io/v1alpha1
kind: Resource
metadata:
  name: user-database
  description: PostgreSQL database for user data
spec:
  type: database
  lifecycle: production
  owner: team-a
  system: my-system
```

{{% alert title="Note" color="primary" %}}
Notice how components reference each other through `providesApis` and `consumesApis`. This creates a dependency graph that Backstage visualizes automatically.
{{% /alert %}}


### Register the Component via URL (GIT)

First you have to push the file in a Git repository!

Navigate to the Backstage Home-Page:

1. Click on "Create..." in the sidebar
2. Click "Register Existing Component"
3. Enter the URL to your `catalog-info.yaml` file
4. Click "Analyze" and then "Import"

Checkout the new entities. You can navigate between them by clicking on relations.

![Backstage Catalog](/docs/02/entities.png)


## Task {{% param sectionnumber %}}.3: Define Teams and Ownership

Ownership is crucial for accountability. Let's define teams in the catalog.

Create a `catalog-org.yaml` file in the backstage-data folder:

```yaml
---
apiVersion: backstage.io/v1alpha1
kind: Group
metadata:
  name: team-a
  description: Platform Engineering Team
spec:
  type: team
  profile:
    displayName: Platform Engineering
    email: platform@example.com
  children: []
  members:
    - john.doe
    - jane.smith
---
apiVersion: backstage.io/v1alpha1
kind: User
metadata:
  name: john.doe
  description: Senior Platform Engineer
spec:
  profile:
    displayName: John Doe
    email: john.doe@example.com
  memberOf:
    - team-a
---
apiVersion: backstage.io/v1alpha1
kind: User
metadata:
  name: jane.smith
  description: Platform Engineer
spec:
  profile:
    displayName: Jane Smith
    email: jane.smith@example.com
  memberOf:
    - team-a
```

Register this in your `app-config.yaml`:

```yaml
catalog:
  locations:
    - type: file
      target: ../../backstage-data/catalog-org.yaml
      rules:
        - allow: [User, Group]
```

After restarting, when you view components, you'll see the actual team members who own them!


## Best Practices for Catalog Management

As you build out your catalog, keep these best practices in mind:

1. **Keep catalog files with the code**: Store `catalog-info.yaml` in the same repository as the component
2. **Use consistent naming**: Follow a naming convention (e.g., kebab-case)
3. **Tag appropriately**: Use tags for technology, team, and purpose
4. **Define clear ownership**: Every component should have an owner
5. **Document relationships**: Use `dependsOn`, `providesApis`, and `consumesApis`
6. **Keep it up to date**: Automate catalog updates through CI/CD
7. **Use systems and domains**: Group related components for better organization


## Summary

In this chapter, you:

* ✅ Created and registered your first catalog component
* ✅ Built a complete system with multiple entities
* ✅ Defined teams and ownership

Your Backstage catalog is now populated with data that represents your software ecosystem!  
