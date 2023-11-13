variable "base_name" {
  description = "Common prefix used for naming resources of this project"
  default     = "wma-doc-bin"
}
variable "common_tags" {
  description = "Common tags used in resources of this project"
  default = {
    "source" = "tf-wma-doc-bin"
  }
}

#variable "kms_deletion_days" {
#  default = 7
#  type    = number
#}

variable "lambda_python_runtime" {
  default = "python3.11"
  type    = string
}

variable "lambda_timeout" {
  default = 10
  type    = number
}

variable "api_gateway_custom_domain_name" {
  default = "files.clueless.engineer"
  type    = string
}
