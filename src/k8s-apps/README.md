# k8s-apps - ArgoCD-Managed Applications

This directory contains applications managed by ArgoCD via the **app-of-apps** pattern.

## How it works

1. Atmos deploys ArgoCD via Helmfile (`components/helmfile/platform/`)
2. ArgoCD's root application (`argocd-root-app.yaml`) watches this directory
3. Each subdirectory with an `application.yaml` becomes an ArgoCD Application
4. ArgoCD syncs the manifests automatically

## Why is this separate from `components/`?

```
components/          <-- Deployed by Atmos (Terraform + Helmfile)
                         Infrastructure and platform operators

src/k8s-apps/        <-- Deployed by ArgoCD (GitOps)
                         Applications that run on the platform
```

- **`components/`** = things that bootstrap the platform (cluster, PGO operator, ArgoCD itself)
- **`src/k8s-apps/`** = things that run on the platform once it's ready (GitLab, future apps)

This separation means you can add new applications just by adding a folder here — ArgoCD discovers and deploys them automatically.

## Sync Waves

Each manifest uses `argocd.argoproj.io/sync-wave` annotations to control deployment order within an application. Lower numbers deploy first.

## Adding a New Application

```
src/k8s-apps/
└── my-app/
    ├── application.yaml      # ArgoCD Application CR
    └── manifests/
        ├── wave-1-namespace.yaml
        └── wave-2-deployment.yaml
```
