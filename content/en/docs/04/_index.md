---
title: "4. Documentation by TechDocs"
weight: 4
sectionnumber: 4
---

A very integrated way to document the applications and services of a company is provided by the TechDocs [Core Feature](https://backstage.io/plugins/) of Backstage. It is included by default in a Backstage application.

[TechDocs](http://backstage.io/docs/features/techdocs/) brings documentation directly into Backstage, making it easy for developers to find and read documentation alongside their services. The TechDocs plugin can be seen as a wrapper for [MkDocs](https://www.mkdocs.org/).

An other huge benefit is that the documentation lives, as Markdown files, beside the source code. This makes it "normal" for developers to update the docs together with the code changes.


## Task {{% param sectionnumber %}}.1: Setup TechDocs Plugin

TechDocs is already included by default, but let's configure it properly and add documentation to a component.


### Step 1: Configure TechDocs for local development

Make sure that your `app-config.yaml` is configured for TechDocs:

```yaml
techdocs:
  builder: 'local'
  generator:
    runIn: 'local'
  publisher:
    type: 'local'
```


### Step 2: Create documentation

In your `my-sample-service` directory (or any catalog component), create a `docs/` folder:

```bash
mkdir -p examples/my-sample-service/docs
```

Add some content by creating the `docs/index.md` file:

{{< readfile file="/manifests/04/4.1/docs/index.md" code="true" lang="markdown" >}}


### Step 3: Create MkDocs configuration

The `mkdocs.yml` files are used to configure the documentation for this component. Here you also define the structure / navigation of the documentation.

Create a `mkdocs.yml` file in the root of your service (side-by-side with `catalog-info.yaml`):

{{< readfile file="/manifests/04/4.1/mkdocs.yml" code="true" lang="yaml" >}}


### Step 4: Enable TechDocs in catalog

Update your `catalog-info.yaml` to enable TechDocs.

<!-- TODO fix and add highlight again
{{< highlight text "hl_lines=8" >}}
{{< readfile file="/manifests/04/4.1/catalog-info.yaml" code="true" lang="yaml" >}}
{{< / highlight >}}
-->

{{< highlight YAML "hl_lines=8" >}}
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: my-sample-service
  description: A sample microservice for the Backstage catalog
  annotations:
    github.com/project-slug: your-org/my-sample-service
    backstage.io/techdocs-ref: dir:.
  tags:
    - nodejs
    - microservice
spec:
  type: service
  lifecycle: production
  owner: team-a
  system: my-system
{{< / highlight >}}

Now your documentation will be available directly in Backstage in the "Docs" menu or on the "Techdocs" tab of your component!

{{% alert title="Note" color="primary" %}}
The `backstage.io/techdocs-ref: dir:.` annotation tells Backstage where to find the documentation. Use `dir:.` for docs in the same repository, or specify a URL for external documentation sources.
{{% /alert %}}


## Summary

In this chapter, you:

* ✅ Set up TechDocs for component documentation
* ✅ Documented one service

TechDocs integrate the developers documentation easily into Backstage. With the docs-as-code approach it is also convenient to the developers to document.


## Next Steps

Now that you've completed this techlab, you're ready to:

TODO

**Congratulations!** You now have the knowledge to ...
