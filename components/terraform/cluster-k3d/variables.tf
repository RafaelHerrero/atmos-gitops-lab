# Input variables for k3d cluster Terraform component

variable "cluster_name" {
  description = "Name of the k3d cluster"
  type        = string

  validation {
    condition     = length(var.cluster_name) > 0 && length(var.cluster_name) <= 63
    error_message = "Cluster name must be between 1 and 63 characters"
  }
}

variable "servers" {
  description = "Number of server (control-plane) nodes"
  type        = number
  default     = 1

  validation {
    condition     = var.servers >= 1 && var.servers <= 3
    error_message = "Number of servers must be between 1 and 3"
  }
}

variable "agents" {
  description = "Number of agent (worker) nodes"
  type        = number
  default     = 2

  validation {
    condition     = var.agents >= 0 && var.agents <= 10
    error_message = "Number of agents must be between 0 and 10"
  }
}

variable "k3s_version" {
  description = "K3s version to use (e.g., v1.28.5-k3s1)"
  type        = string
  default     = "v1.28.5-k3s1"
}

variable "project_root" {
  description = "Project root directory to mount in the cluster (auto-calculated if not provided)"
  type        = string
  default     = null
}

variable "local_ip" {
  description = "Local IP address for TLS SAN"
  type        = string
  default     = "127.0.0.1"
}

variable "disable_load_balancer" {
  description = "Disable k3d built-in load balancer"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "k3s_extra_args" {
  description = "Additional k3s arguments to pass to the cluster (list of {arg, node_filters})"
  type = list(object({
    arg          = string
    node_filters = list(string)
  }))
  default = []
}
