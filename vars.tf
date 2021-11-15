#
# Variables for TKC Demo
#

variable "thunder_username" {
  description = "Username to use for API access to Thunder node"
  type = string
  default = "admin"
}

variable "thunder_password" {
  description = "Password for Username for API access to Thunder node"
  type = string
  default = "a10"
}

variable "thunder_ip_address" {
  description = "IP address of MGMT port on Thunder node"
  type = string
  default = "10.14.5.33"
}

variable "thunder_vip" {
  description = "IP address of VIP on Thunder node"
  type = string
  default = "10.14.5.44"
}

variable "prov_config_path" {
  description = "Path to a Kubernetes config file" 
  type = string
  default = "./microk8s.config"
}

variable "thunder_glm_token" {
  description = "License Token from A10 GLM System"
  type = string
  default = "A107cxxxxxxx"
}

