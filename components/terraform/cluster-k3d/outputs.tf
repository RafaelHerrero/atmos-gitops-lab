# Outputs for k3d cluster Terraform component

output "cluster_name" {
  description = "Name of the created k3d cluster"
  value       = var.cluster_name
}

output "servers" {
  description = "Number of server (control-plane) nodes"
  value       = var.servers
}

output "agents" {
  description = "Number of agent (worker) nodes"
  value       = var.agents
}

output "k3s_version" {
  description = "K3s version used in the cluster"
  value       = var.k3s_version
}

output "project_root" {
  description = "Project root directory mounted in the cluster"
  value       = local.project_root
}

output "local_ip" {
  description = "Local IP address configured for TLS SAN"
  value       = coalesce(var.local_ip, data.external.local_ip.result.ip)
}

output "cluster_exists" {
  description = "Whether the cluster exists"
  value       = data.external.cluster_exists.result.exists == "true"
}

output "kubeconfig_context" {
  description = "Kubeconfig context name for the cluster"
  value       = "k3d-${var.cluster_name}"
}

output "cluster_endpoint" {
  description = "Cluster API endpoint"
  value       = "https://127.0.0.1:6443"
}

output "tags" {
  description = "Tags applied to the cluster"
  value       = var.tags
}
