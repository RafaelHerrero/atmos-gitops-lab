# DCAF Kubernetes Data Platform

A complete local Kubernetes data platform featuring MinIO, Airflow, Polaris, Trino, Metabase, and Spark Operator.

## 🧩 Reusable Atmos Components

This repository includes production-ready Atmos components that can be vendored into other projects:

- **cluster-k3d** (Terraform) - Local k3d cluster creation
- **platform** (Helmfile) - Complete K8s platform (Vault, ArgoCD, PostgreSQL, GitLab)

See [VENDORING.md](VENDORING.md) for detailed instructions on using these components in your projects.

## 🚀 Quick Start

```bash
# One command to install everything
./install.sh
```

That's it! The installer will:
1. Check prerequisites
2. Install missing tools (kubectl, helm, k3d, mc)
3. Create a K3d cluster
4. Build and deploy Docker images
5. Deploy all components

## 📋 Prerequisites

Before installation, ensure you have:

- **Docker** with at least:
  - 8GB RAM
  - 4 CPUs
  - 20GB disk space
- **macOS or Linux** (Windows/WSL not yet tested)

### Docker Options

**Option 1: Docker Desktop**
```bash
# Download from: https://www.docker.com/products/docker-desktop
```

**Option 2: Colima (macOS)**
```bash
# Install and start Colima
brew install colima
colima start -c 4 -m 10 --disk 20

# Set environment variables (installer will do this automatically)
export DOCKER_HOST="unix://$HOME/.colima/docker.sock"
export K3D_FIX_DNS=0
```

## 📦 Installation

### Full Installation
```bash
./install.sh
```

### Step-by-Step Installation
```bash
# 1. Check if your system is ready
./install.sh --check

# 2. Install required tools (kubectl, helm, k3d, mc)
./install.sh --install-tools

# 3. Create the Kubernetes cluster
./install.sh --create-cluster

# 4. Build and deploy Docker images
./install.sh --build-images

# 5. Deploy all components
./install.sh --deploy-all
```

### Deploy Individual Components
```bash
# Deploy specific components
./install.sh --deploy minio
./install.sh --deploy airflow
./install.sh --deploy polaris
./install.sh --deploy trino
./install.sh --deploy metabase
./install.sh --deploy spark
./install.sh --deploy dbt      # Upload DBT files to MinIO
./install.sh --deploy kafka    # Deploy Kafka (optional, not in deploy-all)
./install.sh --deploy flink    # Deploy Flink (optional, not in deploy-all)
```

## 🎯 Access Your Services

After installation, access the services at:

| Service      | URL                      | Username    | Password    | Purpose                          |
|--------------|--------------------------|-------------|-------------|----------------------------------|
| MinIO UI     | http://minio.localhost   | minioadmin  | minioadmin  | Object storage management        |
| MinIO API    | http://minio-api.localhost | -         | -           | S3-compatible API                |
| Airflow UI   | http://airflow.localhost | admin       | admin       | Workflow orchestration           |
| Trino UI     | http://trino.localhost   | admin       | -           | Distributed SQL query engine     |
| Metabase UI  | http://localhost:30005   | -           | -           | Business intelligence            |
| Kafka UI     | http://kafka.localhost   | -           | -           | Kafka management (optional)      |

**Kafka Ports:**
- **Data Port**: 30045 - Producer/Consumer port for streaming data

**Note:** Polaris (Apache Iceberg REST catalog) runs as a backend service without a UI. Kafka and Flink are optional components deployed separately with `./install.sh --deploy kafka` or `./install.sh --deploy flink` and are **not** included in `--deploy-all`.

### Flink Jobs

Flink runs on a shared session cluster managed by the Flink Kubernetes Operator. Multiple streaming jobs can run on the same cluster, sharing resources efficiently.

**Adding Flink Jobs:**
```bash
# Copy the template
cp src/k8s-repo/flink/flink-deployment.yaml \
   src/k8s-repo/flink/my-job.yaml

# Customize and deploy
kubectl apply -f src/k8s-repo/flink/my-job.yaml

# Check job status
kubectl get flinksessionjob -n flink

# Access Flink UI
kubectl port-forward -n flink svc/example-flink-session-rest 8081:8081
# Open http://localhost:8081
```

See [src/k8s-repo/flink/README.md](src/k8s-repo/flink/README.md) for detailed documentation on adding and managing Flink jobs.


### Data Flow

1. **Data Ingestion**: Airflow orchestrates data pipelines
2. **Processing**: Spark jobs process and transform data
3. **Storage**: MinIO stores raw and processed data (S3-compatible)
4. **Cataloging**: Polaris manages Iceberg table metadata
5. **Querying**: Trino provides distributed SQL queries across data
6. **Visualization**: Metabase connects to Trino for analytics and dashboards

### Components Explained

| Component | Purpose | Technology |
|-----------|---------|------------|
| **MinIO** | S3-compatible object storage serving as the data lake foundation | Object Storage |
| **Airflow** | Workflow orchestration and scheduling for data pipelines | Apache Airflow |
| **Polaris** | Apache Iceberg REST catalog service for managing table metadata | Apache Polaris |
| **Trino** | Distributed SQL query engine for querying data across sources | Trino (formerly Presto) |
| **Metabase** | Business intelligence and data visualization platform | Metabase |
| **Spark Operator** | Kubernetes-native Apache Spark for distributed data processing | Spark on K8s |
| **DBT** | Data transformation tool with models stored in MinIO | dbt Core |
| **Kafka** (optional) | Distributed event streaming platform for real-time data pipelines | Apache Kafka (Strimzi) |
| **Flink** (optional) | Stream processing framework for real-time data pipelines | Apache Flink |

## 🛠️ Management Commands

### Check Platform Status
```bash
./install.sh --status
```

### View Logs
```bash
# List all pods
kubectl get pods --all-namespaces

# View specific pod logs
kubectl logs -n <namespace> <pod-name>

# Follow logs in real-time
kubectl logs -n airflow -l component=webserver --tail=100 -f
```

### Restart Components
```bash
# Restart Airflow
kubectl rollout restart deployment -n airflow airflow-webserver
kubectl rollout restart deployment -n airflow airflow-scheduler
```

### Uninstall
```bash
# Remove specific component
./install.sh --uninstall minio
./install.sh --uninstall airflow

# Remove entire cluster
./install.sh --uninstall

# Remove cluster and all Docker images
./install.sh --uninstall --all
```

### View Help
```bash
./install.sh --help
```

## 📁 Project Structure

```
dcaf-k8s/
├── install.sh                      # Main installation script
├── README.md                       # This file
├── QUICKSTART.md                   # Quick start guide
├── CONTRIBUTING.md                 # Contribution guidelines
│
├── src/
│   ├── deploy/                     # Deployment scripts and configuration
│   │   ├── config.sh               # Configuration variables
│   │   ├── README.md               # Deployment documentation
│   │   └── scripts/                # Modular deployment scripts
│   │       ├── check-prerequisites.sh
│   │       ├── install-tools.sh
│   │       ├── cluster.sh
│   │       ├── docker-images.sh
│   │       ├── deploy-components.sh
│   │       └── uninstall.sh
│   │
│   ├── code-repo/                  # Application code and jobs
│   │   ├── apps/                   # Application images
│   │   │   ├── airflow/            # Custom Airflow image
│   │   │   └── spark-base/         # Base Spark image
│   │   ├── jobs/                   # Data processing jobs
│   │   │   ├── ingestion-dummy-api/
│   │   │   ├── ingestion-spark/
│   │   │   └── tool-exec-dbt/
│   │   ├── dags/                   # Airflow DAGs
│   │   ├── dbt/                    # DBT models and configuration
│   │   └── lib/                    # Shared Python libraries
│   │
│   └── k8s-repo/                   # Kubernetes configurations
│       ├── airflow/                # Airflow Helm values and configs
│       ├── mini-io/                # MinIO manifests
│       ├── polaris/                # Polaris Helm values
│       ├── trino/                  # Trino manifests
│       ├── metabase/               # Metabase Helm values
│       ├── spark-operator/         # Spark Operator configs
│       ├── kafka/                  # Kafka Strimzi Operator configs
│       ├── flink/         # Flink Operator configs
│       └── k8s-cluster/            # K3d cluster configuration
```

## 🔧 Configuration

All configuration is centralized in `src/deploy/config.sh`:

```bash
# Cluster settings
CLUSTER_NAME="flex-deploy-prd-cluster"

# Component ports
MINIIO_PORT="30000"        # MinIO UI
MINIIO_API_PORT="30001"    # MinIO API
AIRFLOW_PORT="30002"       # Airflow UI
TRINO_PORT="30004"         # Trino UI
METABASE_PORT="30005"      # Metabase UI

# MinIO credentials
MINIO_ACCESS_KEY="minioadmin"
MINIO_SECRET_KEY="minioadmin"

# Resource requirements
DOCKER_MIN_RAM_GB=8
DOCKER_MIN_CPU=4
```

Edit this file to customize your deployment.

## 🐳 Docker Image Development

### Docker Images Overview

This project uses a monorepo structure with the following Docker images:

| Image | Purpose | Location | Dependencies |
|-------|---------|----------|--------------|
| **airflow-local** | Custom Airflow with plugins | `src/code-repo/apps/airflow/` | apache/airflow base |
| **spark-base** | Base Spark image for jobs | `src/code-repo/apps/spark-base/` | bitnami/spark base |
| **flink-kafka-kafka** | Flink image for flinksession | `src/code-repo/jobs/flink-kafka-kafka/` | flink-scala base |
| **ingestion-dummy-api** | Sample API ingestion job | `src/code-repo/jobs/ingestion-dummy-api/` | data_lib |
| **ingestion-spark** | Spark ingestion job | `src/code-repo/jobs/ingestion-spark/` | spark-base, data_lib |
| **tool-exec-dbt** | DBT execution container | `src/code-repo/jobs/tool-exec-dbt/` | data_lib |

### Automated Image Builds

The installer automatically discovers and builds all Docker images:

```bash
# Test all builds locally (no k3d cluster required)
./install.sh --test-builds

# Test specific image
./install.sh --test-builds airflow

# Force rebuild without cache
./install.sh --test-builds --no-cache

# Build and deploy to k3d cluster (requires running cluster)
./install.sh --build-images

# Build specific image and deploy
./install.sh --build-images spark-base

# Force rebuild and deploy without cache
./install.sh --build-images --no-cache
```

### Manual Docker Builds

**Important**: Always build from the monorepo root, as Dockerfiles reference shared libraries in `lib/data_lib`.

```bash
# From project root
cd /path/to/dcaf-k8s

# Build Airflow
docker build -t airflow-local:latest \
  -f src/code-repo/apps/airflow/Dockerfile \
  src/code-repo/apps/airflow

# Build spark-base (required for ingestion-spark)
docker build -t spark-base:latest \
  -f src/code-repo/apps/spark-base/dockerfile \
  src/code-repo

# Build ingestion jobs
docker build -t ingestion-dummy-api:latest \
  -f src/code-repo/jobs/ingestion-dummy-api/dockerfile \
  src/code-repo

docker build -t ingestion-spark:latest \
  -f src/code-repo/jobs/ingestion-spark/dockerfile \
  src/code-repo

# Build DBT tool
docker build -t tool-exec-dbt:latest \
  -f src/code-repo/jobs/tool-exec-dbt/dockerfile \
  src/code-repo

# Deploy images to k3d cluster
k3d image import <image-name>:latest -c flex-deploy-prd-cluster
```

**Note**: Do not build from job directories. The build context must be the monorepo root to access shared libraries.

## 🚦 Development Workflow

### Making Code Changes

```bash
# Deploy Flink Operator and jobs
./install.sh --deploy minio
./install.sh --deploy kafka
./install.sh --build-deploy-images flink-kafka-kafka
./install.sh --deploy flink

# Check job status
kubectl get flinksessionjob -n flink

# Access Flink UI
# Open http://flink.localhost
```

### Adding New Data Jobs

1. Create job directory in `src/code-repo/jobs/my-new-job/`
2. Add `dockerfile`, `pyproject.toml`, and source code
3. Use shared library: `from schuberg_data_lib import ...`
4. Build: `./install.sh --build-images`
5. Create Airflow DAG in `src/code-repo/dags/`

### Adding New DAGs

1. Create DAG file in `src/code-repo/dags/`
2. Airflow automatically syncs DAGs from the mounted volume
3. Refresh Airflow UI to see new DAG
4. No restart required (unless changing Airflow configuration)

### DBT Development Workflow

DBT files are automatically uploaded to MinIO during platform setup:

```bash
# 1. Modify DBT models in src/code-repo/dbt/dcaf-dbt/

# 2. Re-upload to MinIO
./install.sh --deploy dbt

# 3. Run DBT via Airflow DAG
# The tool-exec-dbt job reads from MinIO and executes transformations
```

DBT files location in MinIO: `s3://dbt/dcaf-dbt/`

### Testing Locally

```bash
# Test Docker builds without deploying
./install.sh --test-builds

# Deploy to local cluster and test
./install.sh --build-images
kubectl get pods -n airflow
kubectl logs -n airflow <pod-name>

# Access Airflow UI and trigger test DAG
# Open http://localhost:30002 (admin/admin)
```

## 🐛 Troubleshooting

### Cluster Already Exists

```bash
k3d cluster delete flex-deploy-prd-cluster
./install.sh --create-cluster
```

### Docker Build Failed

```bash
# For Colima users, ensure Docker socket is set
export DOCKER_HOST="unix://$HOME/.colima/docker.sock"

# Rebuild with no cache
./install.sh --build-images --no-cache

# Check Docker resources
docker info | grep -E "CPUs|Total Memory"
```

### Pods Won't Start

```bash
# For Colima users
export K3D_FIX_DNS=0

# Check pod status and events
kubectl get pods --all-namespaces
kubectl describe pod <pod-name> -n <namespace>

# Check resource limits
kubectl top nodes
kubectl top pods -n <namespace>
```


### MinIO Client (mc) Commands Fail

```bash
# Install mc if missing
./install.sh --install-tools

# Reconfigure alias
mc alias set local-minio http://localhost:30001 minioadmin minioadmin

# Test connection
mc ls local-minio
```

### Airflow DAGs Not Appearing

Check import errors or dag-processor pod logs

### Image Build Context Errors

Always build from the monorepo root, not from individual job directories:

```bash
# ❌ WRONG - will fail to find shared libraries
cd src/code-repo/jobs/ingestion-dummy-api
docker build -t ingestion-dummy-api:latest .

# ✅ CORRECT - uses monorepo root as context
cd /path/to/dcaf-k8s
docker build -t ingestion-dummy-api:latest \
  -f src/code-repo/jobs/ingestion-dummy-api/dockerfile \
  src/code-repo
```

### Reset Everything

```bash
# Complete removal
./install.sh --uninstall --all

# Fresh installation
./install.sh
```

### Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| `Error: context deadline exceeded` | Cluster creation timeout | Increase Docker resources, retry |
| `COPY failed: file not found` | Wrong build context | Build from monorepo root |
| `mc: <ERROR> Unable to initialize new alias` | MinIO not ready | Wait 30s and retry mc commands |
| `ImagePullBackOff` | Image not in k3d registry | Run `./install.sh --build-images` |
| `CrashLoopBackOff` | Pod failing to start | Check logs: `kubectl logs <pod> -n <namespace>` |

## 🔌 Network & Ports Reference

### External Access Ports

| Service           | URL                        | Protocol | Purpose                |
|-------------------|----------------------------|----------|------------------------|
| MinIO UI          | http://minio.localhost     | HTTP     | Web interface          |
| MinIO API         | http://minio-api.localhost | HTTP     | S3-compatible API      |
| Airflow UI        | http://airflow.localhost   | HTTP     | Web interface          |
| Trino UI          | http://trino.localhost     | HTTP     | Query interface        |
| Metabase UI       | http://localhost:30005     | HTTP     | BI dashboard (NodePort)|
| Kafka UI          | http://kafka.localhost     | HTTP     | Kafka management (optional) |
| Flink UI          | http://flink.localhost     | HTTP     | Flink dashboard (optional) |
| Kafka Data        | localhost:30045            | TCP      | Producer/Consumer port (optional) |
| Trino (DBeaver)   | localhost:8081             | HTTP     | Port-forward for DB tools |

### Internal Service Ports (ClusterIP)

| Port | Service           | Used By              |
|------|-------------------|----------------------|
| 9000 | MinIO API         | Trino, Spark, Jobs   |
| 8080 | Airflow Webserver | Users                |
| 8081 | Trino Coordinator | Metabase, Clients    |
| 8181 | Polaris REST API  | Trino, Spark, Flink  |
| 9092 | Kafka Bootstrap   | Producers, Consumers, Flink |


## 📚 Additional Resources

- [K3d Documentation](https://k3d.io/)
- [Apache Airflow](https://airflow.apache.org/)
- [MinIO](https://min.io/)
- [Trino](https://trino.io/)
- [Apache Iceberg](https://iceberg.apache.org/)
- [Apache Polaris](https://polaris.apache.org/)
- [DBT Documentation](https://docs.getdbt.com/)

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Key areas for contribution:
- Additional data connectors
- More example DAGs
- Enhanced monitoring/observability
- Windows/WSL support
- CI/CD pipeline examples

## 📄 License

[Your License Here]

## 🙏 Acknowledgments

Built with:
- K3d for local Kubernetes
- Helm for package management
- Docker for containerization
- Apache open-source projects (Airflow, Iceberg, Spark, Polaris)



Option 1: Manual Vault CLI Access (Direct Method)
Prerequisites:
- Vault CLI installed locally
- Access to Vault (port-forward or ingress)
- Authentication to Vault (token or Kubernetes service account)
Steps:
1. Port-forward to Vault (if no ingress)
kubectl port-forward -n vault svc/vault 8200:8200
2. Set Vault address
export VAULT_ADDR='http://localhost:8200'
3. Authenticate to Vault
Option A: Using root token (admin access)
# Get the root token from the cluster
export VAULT_TOKEN=$(kubectl get secret vault-main-init-keys -n vault -o jsonpath='{.data.root-token}' | base64 -d)
Option B: Using Kubernetes auth (if you're running in a pod)
# This would be done from inside a pod in the abobora namespace with the correct service account
vault login -method=kubernetes role=postgres-abobora jwt=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
4. Request dynamic credentials
For read/write access:
vault read database/creds/app-readwrite
Output:
Key                Value
---                -----
lease_id           database/creds/app-readwrite/abc123
lease_duration     1h
lease_renewable    true
password           A1b2-C3d4-randomly-generated-xyz
username           v-root-app-readwrite-abc123def456
For read-only access:
vault read database/creds/app-readonly
For analytics (long-lived read-only):
vault read database/creds/analytics
5. Save credentials to variables
export DB_USERNAME=$(vault read -field=username database/creds/app-readonly)
export DB_PASSWORD=$(vault read -field=password database/creds/app-readonly)
Important: Each time you run vault read database/creds/..., Vault creates a NEW set of credentials. If you need to use the same credentials multiple times, save them to variables or a file.
6. Connect to PostgreSQL
Option A: Using psql directly
# Port-forward to PostgreSQL
kubectl port-forward -n abobora svc/abobora-prod-primary 5432:5432
# Connect with dynamic credentials
psql "postgresql://$DB_USERNAME:$DB_PASSWORD@localhost:5432/postgres?sslmode=require"
Option B: Using psql with connection string
psql "postgresql://$DB_USERNAME:$DB_PASSWORD@localhost:5432/postgres?sslmode=require"
Option C: One-liner (fetches credentials and connects immediately)
# Port-forward first
kubectl port-forward -n abobora svc/abobora-prod-primary 5432:5432 &
# Fetch creds and connect in one command
vault read -format=json database/creds/app-readonly | \
  jq -r '"postgresql://" + .data.username + ":" + .data.password + "@localhost:5432/postgres?sslmode=require"' | \
  xargs psql
7. Query your data
-- Example queries
SELECT * FROM your_table LIMIT 10;
SELECT COUNT(*) FROM your_table;
8. When done, revoke the credentials (optional but recommended)
# Get the lease_id from the initial vault read output
vault lease revoke database/creds/app-readonly/abc123
# Or revoke all leases for this role
vault lease revoke -prefix database/creds/app-readonly
---
Option 2: Using ExternalSecrets (Automated for Applications)
This is how your applications would get credentials automatically without manual Vault interaction.
How it works:
1. ExternalSecret resource (likely already created in your cluster)
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: postgres-app-creds
  namespace: abobora
spec:
  refreshInterval: 30m  # Fetch new creds every 30 minutes
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: postgres-app-credentials  # Name of K8s secret to create
  data:
    - secretKey: username
      remoteRef:
        key: database/creds/app-readwrite
        property: username
    - secretKey: password
      remoteRef:
        key: database/creds/app-readwrite
        property: password
2. Check the generated Kubernetes secret
# View the secret (credentials are automatically fetched from Vault)
kubectl get secret postgres-app-credentials -n abobora -o jsonpath='{.data.username}' | base64 -d
kubectl get secret postgres-app-credentials -n abobora -o jsonpath='{.data.password}' | base64 -d
3. Use the secret in your application pod
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
  - name: app
    image: my-app:latest
    env:
    - name: DB_USERNAME
      valueFrom:
        secretKeyRef:
          name: postgres-app-credentials
          key: username
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: postgres-app-credentials
          key: password
    - name: DB_HOST
      value: "abobora-prod-primary.abobora.svc.cluster.local"
    - name: DB_PORT
      value: "5432"
    - name: DB_NAME
      value: "postgres"
---
Option 3: Quick Interactive Access (Simplest for Ad-Hoc Queries)
If you just want to quickly run some queries without dealing with Vault directly:
Method A: Use the existing postgres superuser secret
# Get postgres credentials (created by the operator)
export PGPASSWORD=$(kubectl get secret abobora-prod-pguser-postgres -n abobora -o jsonpath='{.data.password}' | base64 -d)
# Port-forward
kubectl port-forward -n abobora svc/abobora-prod-primary 5432:5432 &
# Connect
psql -h localhost -U postgres -d postgres
Note: This uses the static superuser credentials, not dynamic Vault credentials. It's fine for admin tasks but not recommended for applications.
Method B: Exec into a PostgreSQL pod
# Get the primary pod name
POD=$(kubectl get pod -n abobora -l postgres-operator.crunchydata.com/role=master -o name | head -1)
# Exec into the pod and connect
kubectl exec -n abobora -it $POD -- psql -U postgres
---
Comparison of Methods
| Method | Use Case | Pros | Cons |
|--------|----------|------|------|
| Vault CLI | Admin/developer ad-hoc access | Full control, audited, dynamic creds | Requires Vault setup, manual process |
| ExternalSecrets | Application/service access | Automated, self-renewing, k8s-native | Requires ExternalSecrets operator |
| Static superuser | Quick admin tasks | Simplest, always available | Not audited, high privileges, security risk |
| Pod exec | Emergency admin access | Direct access, no port-forward needed | Requires cluster access, not audited |
---
Recommended Workflow for Your Use Case
For ad-hoc data queries as a developer:
# 1. Setup (one-time)
export VAULT_ADDR='http://localhost:8200'
kubectl port-forward -n vault svc/vault 8200:8200 &
export VAULT_TOKEN=$(kubectl get secret vault-main-init-keys -n vault -o jsonpath='{.data.root-token}' | base64 -d)
# 2. Get database credentials (read-only for safety)
vault read -format=json database/creds/app-readonly > /tmp/db-creds.json
export DB_USER=$(jq -r .data.username /tmp/db-creds.json)
export DB_PASS=$(jq -r .data.password /tmp/db-creds.json)
export LEASE_ID=$(jq -r .lease_id /tmp/db-creds.json)
# 3. Connect to database
kubectl port-forward -n abobora svc/abobora-prod-primary 5432:5432 &
export PGPASSWORD=$DB_PASS
psql -h localhost -U $DB_USER -d postgres
# 4. Run your queries
# SELECT * FROM ...
# 5. Clean up when done
vault lease revoke $LEASE_ID
---
Security Best Practices
1. Use read-only credentials (app-readonly or analytics) for querying data
2. Revoke credentials when done with vault lease revoke
3. Don't share credentials - each person should fetch their own
4. Use shortest TTL needed - credentials auto-expire
5. Never commit credentials to git or store in plaintext files
6. Use port-forward instead of exposing databases publicly






change root user gitlab
kubectl exec -it gitlab-0 -n gitlab -- gitlab-rails console
user = User.find_by(username: 'root')
user.password = 'NewPassword123!'
user.password_confirmation = 'NewPassword123!'
user.save!

# atmos-gitops-lab
