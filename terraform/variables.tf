variable "region" {
  type = string
}

variable "vpc_id" {
  type        = string
  description = "the id of the VPC to provision into"
}

variable "vpc_subnets_private_ids" {
  type        = list(string)
  description = "the ids of the private subnets (2)"
}

variable "ingress_queue_name" {
  type        = string
  description = "the name to use for the queue that events are sent to"
  default     = "resource-events"
}

variable "egress_bus_name" {
  type        = string
  description = "the name to use for the event bus that notifications are set to"
  default     = "resource-notifications"
}

variable "lambda_name" {
  type        = string
  description = "the name of the lambda function as well as the name of the zip file (without the extension)"
  default     = "app-lambda"
}

variable "algorithm" {
  type        = string
  description = "the algorithm that the lambda will use to determine which services to notify"
  default     = "downstream_all"
  validation {
    condition     = contains(["downstream_all", "downstream_adjacent", "downstream_leaves", "upstream_all"], var.algorithm)
    error_message = "valid values for algorithm are [downstream_all, downstream_adjacent, downstream_leaves, upstream_all]"
  }
}