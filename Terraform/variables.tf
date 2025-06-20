variable "project_name" {
  type    = string
  default = "azure-functions-explore"
}

variable "location" {
  type    = string
  default = "UK West"
}

variable "tags" {
  type = map(string)
  description = "Common tags for all resources"
  default = {
    Project   = "azure-functions-explore"
    ManagedBy = "Terraform"
  }
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}