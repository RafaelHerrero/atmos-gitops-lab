# atmos-gitops-lab

A local Kubernetes platform managed with [Atmos](https://atmos.tools/) demonstrating GitOps with ArgoCD, PostgreSQL with Crunchy Data PGO, and GitLab — all deployed on a k3d cluster.

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    Atmos (Orchestrator)                   │
│                                                          │
│  ┌─────────────────────┐   ┌──────────────────────────┐  │
│  │ Terraform            │   │ Helmfile                  │  │
│  │ └─ cluster-k3d       │   │ └─ platform               │  │
│  │    (k3d cluster)     │   │    ├─ PostgreSQL Operator  │  │
│  │                      │   │    └─ ArgoCD               │  │
│  └─────────────────────┘   └──────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
                              │
                    ArgoCD App of Apps
                              │
              ┌───────────────┴───────────────┐
              │         src/k8s-apps/         │
              │  └─ gitlab/                   │
              │     ├─ PostgresCluster (PGO)  │
              │     └─ GitLab CE              │
              └───────────────────────────────┘
```

**Deployment flow:**
1. **Terraform** creates a k3d cluster locally
2. **Helmfile** bootstraps the platform (PGO operator + ArgoCD)
3. **ArgoCD** picks up apps from `src/k8s-apps/` via app-of-apps pattern
4. **GitLab** is deployed by ArgoCD with a PGO-managed PostgreSQL cluster

## Prerequisites

- Docker (8GB RAM, 4 CPUs recommended)
- [k3d](https://k3d.io/)
- [Terraform](https://www.terraform.io/) >= 1.7
- [Helm](https://helm.sh/) 3.x
- [Helmfile](https://github.com/helmfile/helmfile)
- [Atmos](https://atmos.tools/) CLI

## Quick Start

```bash
# Deploy everything (cluster + platform components)
atmos workflow deploy-platform -s local

# Or step by step:
atmos terraform apply cluster-k3d -s local      # Create k3d cluster
atmos helmfile apply platform -s local           # Deploy PGO + ArgoCD
# ArgoCD will automatically deploy GitLab from src/k8s-apps/
```

## Project Structure

```
atmos-gitops-lab/
├── atmos.yaml                              # Atmos CLI configuration
├── components/
│   ├── terraform/
│   │   └── cluster-k3d/                    # k3d cluster creation
│   └── helmfile/
│       └── platform/                       # Platform bootstrap (PGO + ArgoCD)
│           ├── helmfile.yaml
│           ├── values/
│           │   ├── argocd.yaml.gotmpl
│           │   └── postgres-operator.yaml.gotmpl
│           └── manifests/
│               ├── argocd-ingress.yaml
│               └── argocd-root-app.yaml    # App of Apps root
├── src/
│   └── k8s-apps/                           # ArgoCD-managed applications
│       ├── README.md                       # Explains app-of-apps pattern
│       └── gitlab/
│           ├── application.yaml            # ArgoCD Application CR
│           └── manifests/
│               ├── wave-1-postgres-cluster.yaml   # PGO PostgresCluster
│               └── wave-2-gitlab.yaml             # GitLab CE deployment
├── stacks/
│   ├── local.yaml                          # Local environment stack
│   └── catalog/
│       ├── terraform/
│       │   └── cluster-k3d.yaml            # Default cluster values
│       └── helmfile/
│           └── platform.yaml               # Default platform values
└── workflows/
    └── platform.yaml                       # Deployment automation workflows
```

## Accessing Services

```bash
# ArgoCD UI
# URL: http://argocd.localhost
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d

# GitLab
# URL: http://gitlab.localhost
kubectl get secret gitlab-gitlab-initial-root-password -n gitlab \
  -o jsonpath='{.data.password}' | base64 -d
```

## Workflows

```bash
atmos workflow deploy-platform -s local      # Full deploy (cluster + components)
atmos workflow deploy-cluster -s local       # Cluster only
atmos workflow deploy-components -s local    # Components only (cluster must exist)
atmos workflow status -s local               # Check platform status
atmos workflow destroy-platform -s local     # Tear down everything
```

## Cleanup

```bash
# Destroy components only (keep cluster)
atmos workflow destroy-components -s local

# Destroy everything
atmos workflow destroy-platform -s local
```
