variable "azure-subscription-id" {
  type        = string
  default = "3c73a127-8266-47c0-ae2a-ec3717cd8da1"
}

variable "azure-client-id" {
  type        = string
  default = "5988fbea-e3fb-4c7c-bcd9-5d798cf5f8a5"
}

variable "azure-client-secret" {
  type        = string
  default = ".H88Q~jsi2sHJZmzpzDyf9nLn9c2xt0F1AmOdcH9"
}

variable "azure-tenant-id" {
  type        = string
  default = "db086519-96ca-4ffb-8b21-fc8954da3df9"
}


variable "resource_group" {
  description = "Name of the resource group"
  default     = "udacity-devops-project1-rg"
  type        = string
}

variable "packer_image" {
  type  = string
  default = "ud-devops-server-image"
}

variable "packer_resource_group" {
  description = "packer image resource group"
  default     = "az-devops-udacity-rg-image"
  type        = string
}

variable "prefix" {
  default     = "ud-devops-tr"
  type        = string
}

variable "vm-size" {
  type        = string
  description = "VM Size"
  default     = "Standard_B1ls"
}


variable "environment" {
  type        = string
  description = "environment"
  default     = "development"
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "Southeast Asia"
}

variable "network-vnet" {
  type        = string
  default = "10.0.0.0/16"
}

variable "network-subnet" {
  type        = string
  default = "10.0.2.0/24"
}

variable "username" {
  type        = string
  default     = "usr_admin"
}

variable "password" {
  type        = string
  default     = "!P@ssw0rd"
}

variable "num_of_vms" {
  description = "Number of VMs to create"
  default     = 2
  type        = number
}