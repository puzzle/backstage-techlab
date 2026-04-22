---
title: "5.1 Introduction to Plugin usage"
weight: 51
sectionnumber: 5.1
---

Plugins extend Backstage with new functionality, integrations, and visualizations.

In this chapter, you'll learn how to discover, install, and configure existing plugins to enhance your developer portal.


## Understanding the Plugin Ecosystem

Backstage has a rich ecosystem of plugins that fall into several categories:

* **Frontend Plugins**: Add new pages and UI components to the Backstage interface
* **Backend Plugins**: Provide APIs and backend services
* **Scaffolder Actions**: Extend software templates with custom actions
* **Catalog Processors**: Add custom logic for processing catalog entities

{{% alert title="Note" color="primary" %}}
Most plugins are open source and maintained by the Backstage community. You can find them in the [Backstage Plugin Marketplace](https://backstage.io/plugins) or on npm.
{{% /alert %}}


## Task {{% param sectionnumber %}}.1: Explore Available Plugins

Before installing plugins, let's explore what's available.

Visit the Backstage Plugin Marketplace:

* Go to [https://backstage.io/plugins](https://backstage.io/plugins)
* Browse categories like CI/CD, Monitoring, Cloud, Security, etc.
* Note plugins that would be useful for your organization

Popular plugins include:

* **Kubernetes**: View and manage Kubernetes resources
* **GitHub Actions**: Monitor CI/CD pipelines
* **Gitlab CI/CD**: Monitor CI/CD pipelines
* **TechDocs**: Documentation platform
* **Grafana**: Metrics and dashboards
* **ArgoCD**: CD pipeline visualization


## Task {{% param sectionnumber %}}.2: Install your first plugin

Learn how to install plugins by using the [Tech Radar](https://github.com/backstage/community-plugins/tree/main/workspaces/tech-radar/plugins/tech-radar) plugin.


### Step 1: Check Tech Radar plugin documentation

Visit the Backstage Plugin Marketplace again:

* Go to [https://backstage.io/plugins](https://backstage.io/plugins)
* Type `radar` into the `Search plugins...` search field.
* Click on `Explore` on the Tech Radar card.

Some plugins live in the [backstage/backstage](https://github.com/backstage/backstage) repository but there are other locations for plugins like [backstage/community-plugins](https://github.com/backstage/community-plugins) or [redhat-developer/rhdh-plugins](https://github.com/redhat-developer/rhdh-plugins).

Read the `Purpose` and `Getting Started` sections.

{{% alert title="Note" color="primary" %}}
Backstage changed their plugin integration mechanism recently. This for backend and frontend plugins.

Some plugins are still using older versions of the integrations. This has to be respected when installing them.
{{% /alert %}}


### Step 1: Install the Tech Radar plugin

It is enough to install the NPM dependency.

Run the `yarn` command from your app root (`my-backstage-app`):

```bash
yarn --cwd packages/app add @backstage-community/plugin-tech-radar
```

When you start your Backstage application, the Tech Radar is integrated by menu `Tech Radar` and route: [http://localhost:3000/tech-radar](http://localhost:3000/tech-radar).

But it only shows some example data. This is because we only installed a [Standalone plugin](https://backstage.io/docs/overview/architecture-overview#standalone-plugins). They run completely in the browser and display only static data.


### Step 2: Add the Tech Radar backend plugin

Data is not loaded inside a frontend plugin. Most frontend plugins have a corresponding backend plugin loading and providing the needed data.

This is also the case for the Tech Radar plugin.

Follow the plugin [installation instructions](https://github.com/backstage/community-plugins/tree/main/workspaces/tech-radar/plugins/tech-radar-backend#integrating-into-a-backstage-instance) and use the new backend system guidance.


### Step 3: Configure the Tech Radar plugin

We prepared a `sampleTechRadar.json` file with following content:

<details>
  <summary>Explore the Tech Radar definition</summary>

{{< readfile file="/static-content/sampleTechRadar.json" code="true" lang="json" >}}

</details>

Configure your Backstage app to use our Tech Radar configuration file.
Extend your `app-config.yaml` file with the configuration for your new plugin:

```yaml
techRadar:
  url: https://backstage-techlab.puzzle.ch/static/sampleTechRadar.json
```

Restart your Backstage app to see the changed content on your Tech Radar.

{{% alert title="Warning" color="secondary" %}}
Backstage does not read from any location. You should have gotten an error:

```bash
2026-04-20T15:12:11.631Z tech-radar warn Failed to read file from https://backstage-techlab.puzzle.ch/static/sampleTechRadar.json with provided integrations (error is "Reading from 'https://backstage-techlab.puzzle.ch/static/sampleTechRadar.json' is not allowed. You may need to configure an integration for the target host, or add it to the configured list of allowed hosts at 'backend.reading.allow'"). 
```

{{% /alert %}}

To enable reading from a host, it has to be allowed. Add the following configuration to the `backend:` section of your `app-config.yaml`:

```yaml
backend:
  reading:
    allow:
      - host: backstage-techlab.puzzle.ch
```

After restarting Backstage, you should not get the error any more and see a Backstage entry in the Tech Radar.


## Best Practices for Plugin Management

1. **Start with essential plugins**: Don't install everything at once
2. **Read documentation**: Each plugin has specific configuration requirements
3. **Test in development**: Always test plugins locally before production
4. **Monitor performance**: Some plugins can impact load times
5. **Keep plugins updated**: Regularly update to get bug fixes and features
6. **Use semantic versioning**: Pin major versions to avoid breaking changes
7. **Configure authentication**: Ensure plugins respect your auth setup
8. **Document customizations**: Keep notes on configuration changes


## Troubleshooting Common Plugin Issues

**Plugin not appearing:**

* Check that you've added it to the correct Entity Page
* Verify the component has required annotations
* Check browser console for errors

**Backend plugin errors:**

* Ensure backend plugin is registered in `index.ts`
* Verify configuration in `app-config.yaml`
* Check backend logs for detailed errors

**Authentication issues:**

* Verify integration tokens are set correctly
* Check token permissions/scopes
* Ensure environment variables are loaded


## Summary

In this chapter, you:

* ✅ Explored the Backstage plugin ecosystem
* ✅ Installed and configured the Tech Radar plugin
* ✅ Got some Best Practice ant Troubleshooting hints

Plugins are what make Backstage adaptable to your organization's needs. By carefully selecting and configuring plugins, you create a developer portal that truly reduces cognitive load and improves the developer experience.


## Next Steps

Now that you've completed this lab, you could:

1. **Install more plugins**: Do the [Additional Labs](../additional/) where you need the GitHub Integration for interesting plugins.
2. **Customize the Look and Feel**: Do the [next lab](../../06/) and change the appearance of your Backstage App.


<!-- TODO CRA: add as wrap up of the whole lab

## Next Steps

Now that you've completed this lab, you're ready to:

1. **Identify your organization's needs**: What tools do your developers use daily?
2. **Plan your plugin strategy**: Which plugins would provide the most value?
3. **Build custom plugins**: Create plugins for internal tools and services
4. **Roll out to teams**: Start with a pilot team and gather feedback
5. **Iterate and improve**: Continuously enhance your developer portal

**Congratulations!** You now have the knowledge to install, customize, and extend Backstage to massively improve Developer Experience in your organization.  

-->
