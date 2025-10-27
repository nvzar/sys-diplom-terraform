output "bastion_public_ip" {
  description = "Public IP address of bastion host"
  value       = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
}

output "zabbix_public_ip" {
  description = "Public IP address of Zabbix server"
  value       = yandex_compute_instance.zabbix.network_interface.0.nat_ip_address
}

output "kibana_public_ip" {
  description = "Public IP address of Kibana server"
  value       = yandex_compute_instance.kibana.network_interface.0.nat_ip_address
}

output "web-1_private_ip" {
  description = "Private IP of web-1"
  value       = yandex_compute_instance.web-1.network_interface.0.ip_address
}

output "web-2_private_ip" {
  description = "Private IP of web-2"
  value       = yandex_compute_instance.web-2.network_interface.0.ip_address
}

output "elasticsearch_private_ip" {
  description = "Private IP of Elasticsearch"
  value       = yandex_compute_instance.elasticsearch.network_interface.0.ip_address
}

output "web-1_fqdn" {
  description = "FQDN of web-1"
  value       = "${yandex_compute_instance.web-1.name}.ru-central1.internal"
}

output "web-2_fqdn" {
  description = "FQDN of web-2"
  value       = "${yandex_compute_instance.web-2.name}.ru-central1.internal"
}
