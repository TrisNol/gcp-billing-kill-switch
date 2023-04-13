output "cloud_function_id" {
  value       = google_cloudfunctions2_function.function.id
  description = "ID of the cloud function managing the billing account"
}

output "billing_budget_id" {
  value       = google_billing_budget.default.id
  description = "ID of the created billing budget"
}
