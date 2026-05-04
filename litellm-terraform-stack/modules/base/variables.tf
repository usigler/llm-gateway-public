variable "name" {
  description = "Standard name to be used as prefix on all resources."
  type        = string
}

variable "vpc_id" {
  description = "ID of an existing VPC to use. If not provided, a new VPC will be created."
  type        = string
  default     = ""
}

variable "ecrLitellmRepository" {
  type        = string
  description = "Name of the LiteLLM ECR repository"
}

variable "ecrMiddlewareRepository" {
  type        = string
  description = "Name of the Middleware ECR repository"
}

variable "deployment_platform" {
  description = "Which platform to deploy (ECS or EKS)"
  type        = string
  
  validation {
    condition     = can(regex("^(ECS|EKS)$", upper(var.deployment_platform)))
    error_message = "DEPLOYMENT_PLATFORM must be either 'ECS' or 'EKS' (case insensitive)."
  }
}

variable "disable_outbound_network_access" {
    description = "Whether to disable outbound network access"
    type = bool
}

variable "create_vpc_endpoints_in_existing_vpc" {
  type    = bool
  description = "If using an existing VPC, set this to true to also create interface/gateway endpoints within it."
}

variable "create_vpc_endpoints" {
  type        = bool
  default     = true
  description = "Whether to create VPC endpoints. Set to false to skip endpoint creation entirely."
}

variable "rds_multi_az" {
  type        = bool
  default     = true
  description = "Whether to enable Multi-AZ for the RDS instance."
}

variable "hostedZoneName" {
  description = "Hosted zone name"
  type        = string
  default     = ""
}

variable "publicLoadBalancer" {
  description = "Whether the load balancer is public or private"
  type = bool
}

variable "create_private_hosted_zone_in_existing_vpc" {
  description = "In the case publicLoadBalancer=false (meaning we need a private hosted zone), and an vpc_id is provided, decides whether we create a private hosted zone, or assume one already exists and import it"
  type        = bool
}

variable "rds_instance_class" {
  type        = string
  description = "The instance class for the RDS database"
}

variable "rds_allocated_storage" {
  type        = number
  description = "The allocated storage in GB for the RDS database"
}

variable "redis_node_type" {
  type        = string
  description = "The node type for Redis clusters"
}

variable "redis_num_cache_clusters" {
  type        = number
  description = "The number of cache clusters for Redis"
}

variable "use_route53" {
  description = "Whether to use Route53 for DNS management. If false, no Route53 resources will be created."
  type        = bool
  default     = false
}

variable "vpc_cidr" {
  description = "CIDR block for the new VPC."
  type        = string
  default     = "10.225.192.0/20"
}

variable "waf_allowed_networks" {
  description = "Comma-separated list of CIDRs allowed by WAF. All other traffic will be blocked."
  type        = string
  default     = ""
}

variable "subnet_public_1_cidr" {
  description = "CIDR block for public subnet 1."
  type        = string
  default     = "10.225.192.0/24"
}

variable "subnet_public_2_cidr" {
  description = "CIDR block for public subnet 2."
  type        = string
  default     = "10.225.193.0/24"
}

variable "subnet_private_1_cidr" {
  description = "CIDR block for private subnet 1 (app)."
  type        = string
  default     = "10.225.194.0/24"
}

variable "subnet_private_2_cidr" {
  description = "CIDR block for private subnet 2 (app)."
  type        = string
  default     = "10.225.195.0/24"
}

variable "subnet_db_1_cidr" {
  description = "CIDR block for private DB subnet 1."
  type        = string
  default     = "10.225.196.0/24"
}

variable "subnet_db_2_cidr" {
  description = "CIDR block for private DB subnet 2."
  type        = string
  default     = "10.225.197.0/24"
}
