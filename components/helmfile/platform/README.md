# platform - Atmos Helmfile Component

Bootstraps the Kubernetes platform with PostgreSQL Operator and ArgoCD.

## Components Deployed

1. **PostgreSQL Operator** (Crunchy Data PGO) - Database operator
2. **ArgoCD** - GitOps continuous delivery

GitLab and its PostgreSQL cluster are deployed by ArgoCD via the app-of-apps pattern from `src/k8s-apps/`.

## Usage

### Deploy

```bash
atmos helmfile apply platform -s local
```

### Destroy

```bash
atmos helmfile destroy platform -s local
```

## Deployment Order

1. **Wave 1:** PostgreSQL Operator
2. **Wave 2:** ArgoCD (depends on PGO)

After ArgoCD is deployed, it automatically discovers and syncs applications from `src/k8s-apps/`.

## Accessing Services

```bash
# ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d
```

## Structure

```
platform/
├── helmfile.yaml                    # Release definitions
├── values/
│   ├── argocd.yaml.gotmpl          # ArgoCD Helm values
│   └── postgres-operator.yaml.gotmpl  # PGO Helm values
└── manifests/
    ├── argocd-ingress.yaml          # ArgoCD ingress (localhost)
    └── argocd-root-app.yaml         # App of Apps root application
```
