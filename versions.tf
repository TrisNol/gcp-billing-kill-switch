terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.26.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.4.2"
    }
  }
}
