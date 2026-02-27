# cluster-k3d - Atmos Terraform Component

Creates a k3d (k3s in Docker) cluster with Atmos integration.

## Features

- Automated k3d cluster creation via Terraform
- Multi-node support (servers + agents)
- Volume mounting for local development
- TLS SAN configuration
- Customizable k3s arguments
- Port mapping for services

## Usage

### Stack Configuration Example

```yaml
# stacks/local.yaml
components:
  terraform:
    cluster-k3d:
      vars:
        cluster_name: "my-cluster"
        servers: 1
        agents: 2
```

### Deploy

```bash
atmos terraform apply cluster-k3d -s local
```

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| cluster_name | string | (required) | Name of the k3d cluster |
| servers | number | 1 | Number of control-plane nodes |
| agents | number | 2 | Number of worker nodes |
| k3s_version | string | "v1.35.0-k3s3" | K3s version |
| project_root | string | null | Project root to mount (auto-detected) |
| local_ip | string | "127.0.0.1" | Local IP for TLS SAN |
| disable_load_balancer | bool | false | Disable k3d built-in load balancer |
| k3s_extra_args | list(object) | [] | Additional k3s arguments |

## Outputs

| Name | Description |
|------|-------------|
| cluster_name | Name of the created cluster |
| kubeconfig_context | Kubeconfig context name |
| cluster_endpoint | Cluster API endpoint |

## Requirements

- Docker or Colima running
- k3d CLI installed
- Terraform >= 1.7
