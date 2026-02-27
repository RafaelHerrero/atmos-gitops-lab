# k3d Cluster Terraform Component
# Creates a k3d cluster using k3d CLI via null_resource

# Local variables
locals {
  # Calculate project root: 3 levels up from component directory
  # /path/to/project/components/terraform/cluster-k3d -> /path/to/project
  calculated_project_root = abspath("${path.cwd}/../../..")

  # Use provided project_root if set (not null and not empty), otherwise use calculated
  project_root = var.project_root != null && var.project_root != "" ? var.project_root : local.calculated_project_root
}

# Data source to get local IP for TLS SAN
data "external" "local_ip" {
  program = ["bash", "-c", <<-EOT
    if [[ "$OSTYPE" == "darwin"* ]]; then
      LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || echo "127.0.0.1")
    else
      LOCAL_IP=$(hostname -I | awk '{print $1}' || echo "127.0.0.1")
    fi
    echo "{\"ip\": \"$LOCAL_IP\"}"
  EOT
  ]
}

# Generate k3d cluster configuration file
resource "local_file" "k3d_config" {
  filename = "${path.module}/.atmos-k3d-${var.cluster_name}.yaml"
  content  = <<-EOT
apiVersion: k3d.io/v1alpha5
kind: Simple
metadata:
  name: ${var.cluster_name}
servers: ${var.servers}
agents: ${var.agents}

volumes:
  - volume: ${local.project_root}:/mnt/atmos-gitops-lab
    nodeFilters:
      - all

options:
  k3s:
    extraArgs:
      - arg: "--tls-san=${coalesce(var.local_ip, data.external.local_ip.result.ip)}"
        nodeFilters:
          - servers:*
      - arg: "--service-node-port-range=30000-30050"
        nodeFilters:
          - servers:*
%{for extra_arg in var.k3s_extra_args~}
      - arg: "${extra_arg.arg}"
        nodeFilters:
%{for filter in extra_arg.node_filters~}
          - ${filter}
%{endfor~}
%{endfor~}

ports:
  - port: 30000-30050:30000-30050
    nodeFilters:
      - servers:0
  - port: 8000:8000
    nodeFilters:
      - loadbalancer
  - port: 80:80
    nodeFilters:
      - loadbalancer
  - port: 443:443
    nodeFilters:
      - loadbalancer
EOT

  lifecycle {
    create_before_destroy = true
  }
}

# Check if cluster already exists
data "external" "cluster_exists" {
  depends_on = [local_file.k3d_config]

  program = ["bash", "-c", <<-EOT
    if k3d cluster list 2>/dev/null | grep -q "^${var.cluster_name}"; then
      echo '{"exists": "true", "name": "${var.cluster_name}"}'
    else
      echo '{"exists": "false", "name": "${var.cluster_name}"}'
    fi
  EOT
  ]
}

# Create k3d cluster
resource "null_resource" "k3d_cluster" {
  depends_on = [local_file.k3d_config]

  triggers = {
    cluster_name = var.cluster_name
    config_file  = local_file.k3d_config.filename
    k3s_version  = var.k3s_version
    servers      = var.servers
    agents       = var.agents
    project_root = local.project_root
    config_hash  = sha256(local_file.k3d_config.content)
  }

  # Create cluster if it doesn't exist
  provisioner "local-exec" {
    when    = create
    command = <<-EOT
      if k3d cluster list 2>/dev/null | grep -q "^${self.triggers.cluster_name}"; then
        echo "Cluster ${self.triggers.cluster_name} already exists, skipping creation"
      else
        echo "Creating k3d cluster ${self.triggers.cluster_name}..."
        k3d cluster create --config ${self.triggers.config_file} --image rancher/k3s:${self.triggers.k3s_version}
        
        echo "Waiting for cluster nodes to be registered..."
        sleep 10
        until kubectl get nodes &>/dev/null; do
          sleep 2
        done
        echo "Cluster nodes registered successfully"
      fi
    EOT
  }

  # Delete cluster on destroy
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      if k3d cluster list 2>/dev/null | grep -q "^${self.triggers.cluster_name}"; then
        echo "Deleting k3d cluster ${self.triggers.cluster_name}..."
        k3d cluster delete ${self.triggers.cluster_name}
      else
        echo "Cluster ${self.triggers.cluster_name} does not exist, skipping deletion"
      fi
    EOT
  }
}

# Wait for cluster to be fully ready (nodes registered)
resource "null_resource" "wait_for_cluster" {
  depends_on = [null_resource.k3d_cluster]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for cluster to be ready..."
      max_attempts=30
      attempt=0
      
      while [ $attempt -lt $max_attempts ]; do
        if kubectl get nodes &>/dev/null; then
          echo "Cluster is ready!"
          exit 0
        fi
        attempt=$((attempt + 1))
        echo "Waiting for cluster... (attempt $attempt/$max_attempts)"
        sleep 2
      done
      
      echo "ERROR: Cluster failed to become ready within timeout"
      exit 1
    EOT
  }
}

# Update kubeconfig for the cluster
resource "null_resource" "update_kubeconfig" {
  depends_on = [null_resource.wait_for_cluster]

  triggers = {
    cluster_name = var.cluster_name
  }

  provisioner "local-exec" {
    command = "k3d kubeconfig merge ${self.triggers.cluster_name} --kubeconfig-merge-default"
  }
}
