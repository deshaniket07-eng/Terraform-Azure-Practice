variable "rg_name" {
  description = "Existing Resource Group name"
  type        = string
  default     = "Rg-Aniket"
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "westeurope"
}
