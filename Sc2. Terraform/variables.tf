variable "nics" {
  description = "The address prefix to use for the nics."
  type        = list(string)
  default     = ["10.0.1.5","10.0.2.5"]
}
variable "virtual_machine_hostnames" {
  description = "The address prefix to use for the Vmname."
  type        = list(string)
  default     = ["VMNode1","VMNode2"]
}

variable "subnet_prefixes" {
  description = "The address prefix to use for the subnet."
  type        = list(string)
  default     = ["10.0.1.0/24","10.0.2.0/24"]
}