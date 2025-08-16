variable "project_id" {
  type = string
}

variable "billing_account" {
  type        = string
  description = "ID of the billing account to attach the budget to"
}

variable "region" {
  type        = string
  description = "Region to create resources in"
}

variable "storage_bucket" {
  type        = string
  description = "Name of the storage bucket where the central cloud function will be placed"
}

variable "functions_sa_email" {
  type        = string
  description = "Email of a pre-defined service account with roles/billing.admin permission. Defaults to: null"
  default     = null
}

variable "budget" {
  type        = number
  description = "Max. monthly budget"
  default     = 15
}

variable "currency" {
  type        = string
  description = "Currency to be used for the budget"
  default     = "EUR"
  validation {
    condition     = can(regex("^[A-Z]{3}$", var.currency))
    error_message = "Must be a valid three-letter ISO-4217 currency code (e.g., USD, EUR)."
  }
}
