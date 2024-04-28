data "google_billing_account" "account" {
  billing_account = var.billing_account
}

resource "google_pubsub_topic" "budget_topic" {
  name = "billing_budget"
}

resource "google_service_account" "cloud_function_sa" {
  count        = var.functions_sa_email == null ? 1 : 0
  account_id   = "gcf-budget-kill-switch-sa"
  display_name = "Budget Kill Switch Service Account"
}

resource "google_billing_account_iam_member" "admin" {
  depends_on = [
    google_service_account.cloud_function_sa[0]
  ]
  billing_account_id = data.google_billing_account.account.id
  role               = "roles/billing.admin"
  member             = "serviceAccount:${google_service_account.cloud_function_sa[0].email}"
}

resource "google_billing_budget" "default" {
  depends_on = [
    google_pubsub_topic.budget_topic
  ]
  billing_account = data.google_billing_account.account.id
  display_name    = "Kill Switch Budget"

  budget_filter {
    projects        = ["projects/${var.project_id}"]
    calendar_period = "MONTH"
  }

  amount {
    specified_amount {
      currency_code = var.currency
      units         = var.budget
    }
  }
  threshold_rules {
    threshold_percent = 1
  }

  # Note: https://stackoverflow.com/questions/64574283/permission-denied-when-creating-budget-alert-with-cloud-function-in-google-cloud
  all_updates_rule {
    pubsub_topic = google_pubsub_topic.budget_topic.id
  }
}

data "archive_file" "archive_cloud_function" {
  type        = "zip"
  source_dir  = "${path.module}/code"
  output_path = "artifacts/budget-kill-switch/index.zip"
}

resource "google_storage_bucket_object" "object" {
  name   = "budget-kill-switch.zip"
  bucket = var.storage_bucket
  source = data.archive_file.archive_cloud_function.output_path
}

resource "google_cloudfunctions2_function" "function" {
  depends_on = [
    google_storage_bucket_object.object
  ]
  name        = "budget-kill-switch-function"
  location    = var.region
  description = "Cloud function deactivating billling account"

  build_config {
    runtime     = "python312"
    entry_point = "stop_billing"
    source {
      storage_source {
        bucket = var.storage_bucket
        object = google_storage_bucket_object.object.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    min_instance_count = 0
    available_memory   = "256M"
    timeout_seconds    = 60

    ingress_settings               = "ALLOW_INTERNAL_ONLY"
    all_traffic_on_latest_revision = true
    service_account_email          = var.functions_sa_email != null ? var.functions_sa_email : google_service_account.cloud_function_sa[0].email
    environment_variables = {
      GCP_PROJECT = var.project_id
    }
  }
  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.budget_topic.id
    retry_policy   = "RETRY_POLICY_RETRY"
  }
}
