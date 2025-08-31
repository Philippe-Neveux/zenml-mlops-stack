# DNS Module Outputs

output "zone_name" {
  description = "Name of the DNS zone"
  value       = google_dns_managed_zone.main.name
}

output "zone_dns_name" {
  description = "DNS name of the zone"
  value       = google_dns_managed_zone.main.dns_name
}

output "name_servers" {
  description = "Name servers for the zone"
  value       = google_dns_managed_zone.main.name_servers
}

output "zenml_fqdn" {
  description = "Fully qualified domain name for ZenML"
  value       = "zenml.${var.domain_name}"
}

output "root_fqdn" {
  description = "Root domain FQDN"
  value       = var.domain_name
}
