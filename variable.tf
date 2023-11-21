variable "namespace" {
  description = "The namespace in which cansandra will be deployed"
  default     = "cassandra"
}

variable "cassandra_name" {
  default     = "web3-auth"
  description = "name of the cassandra kubernetes deployment"
}

variable "cluster_size" {
  default     = "1"
  description = "number of replicas to be deployed"
}

variable "storage_size" {
  default     = "10Gi"
  description = "The storage class size"
}

variable "storage_class_name" {
  default     = "standard"
  description = "The storage class name"
}


