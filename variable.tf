variable "namespace" {
  description = "The namespace in which cansandra will be deployed"
  default     = "cassandra"
}
variable "region" {
  description = "The region in which to create the VPC network"
  type        = string
  default     = "us-central1"
}

variable "project_id" {
  description = "The project in which to hold the components"
  type        = string
  default     = "web3-auth-405822"
}

