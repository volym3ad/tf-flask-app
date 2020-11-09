variable "region" {
  description = "AWS region to deploy to."
  default     = "us-east-1"
}

variable "instance_type" {
  default = "t3.nano"
}

variable "ami" {
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
