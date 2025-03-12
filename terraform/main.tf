provider "google" {
  project = var.PROJECT_ID
  credentials = file(var.GOOGLE_APPLICATION_CREDENTIALS)
}

resource "google_pubsub_topic" "logs_topic" {
    name = "logs-topic"
}

resource "google_storage_bucket" "function_bucket" {
    name     = "log_processor_bucket"
    location = "US"
}

resource "google_storage_bucket_object" "function_zip" {
    name   = "function.zip"
    bucket = google_storage_bucket.function_bucket.name
    source = "../cloud_function/function.zip"
}

resource "google_cloudfunctions_function" "log_processor" {
    name                  = "log-processor"
    description           = "Process log data"
    runtime               = "python39"
    entry_point           = "process_log_data"
    source_archive_bucket = google_storage_bucket.function_bucket.name
    source_archive_object = google_storage_bucket_object.function_zip.name
    region                = "us-central1"

    event_trigger {
        event_type = "google.pubsub.topic.publish"
        resource   = google_pubsub_topic.logs_topic.id
    }
}

resource "google_bigquery_dataset" "logs_dataset" {
    dataset_id  = "logs_dataset"
    location    = "US"
}

resource "google_bigquery_table" "logs_table" {
  dataset_id = google_bigquery_dataset.logs_dataset.dataset_id
  table_id   = "logs_table"

  schema = <<EOF
[
  {
    "name": "timestamp",
    "type": "TIMESTAMP",
    "mode": "REQUIRED",
    "description": "The timestamp when the log entry was created"
  },
  {
    "name": "log_level",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "The severity of the log (e.g., INFO, ERROR, etc.)"
  },
  {
    "name": "message",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "The log message"
  }
]
EOF

  time_partitioning {
    type = "DAY"
  }

  clustering = ["log_level"]
}
