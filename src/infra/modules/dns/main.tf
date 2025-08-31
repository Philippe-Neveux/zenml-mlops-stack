# DNS Module - Main Configuration

# DNS Zone
resource "google_dns_managed_zone" "main" {
  name        = replace(var.domain_name, ".", "-")
  dns_name    = "${var.domain_name}."
  description = "DNS zone for ${var.domain_name}"
  project     = var.project_id

  dnssec_config {
    state = "on"
  }
}

# A record for ZenML
resource "google_dns_record_set" "zenml" {
  name         = "zenml.${google_dns_managed_zone.main.dns_name}"
  managed_zone = google_dns_managed_zone.main.name
  type         = "A"
  ttl          = var.ttl
  project      = var.project_id

  rrdatas = [var.zenml_ip_address]
}

# A record for root domain (optional)
resource "google_dns_record_set" "root" {
  name         = google_dns_managed_zone.main.dns_name
  managed_zone = google_dns_managed_zone.main.name
  type         = "A"
  ttl          = var.ttl
  project      = var.project_id

  rrdatas = [var.zenml_ip_address]
}

# Wildcard A record for additional services
resource "google_dns_record_set" "wildcard" {
  name         = "*.${google_dns_managed_zone.main.dns_name}"
  managed_zone = google_dns_managed_zone.main.name
  type         = "A"
  ttl          = var.ttl
  project      = var.project_id

  rrdatas = [var.zenml_ip_address]
}
