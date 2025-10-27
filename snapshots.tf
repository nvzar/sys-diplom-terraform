# Snapshot Schedule для всех ВМ

# Для web-1
resource "yandex_compute_snapshot_schedule" "web-1-schedule" {
  name           = "web-1-daily-snapshot"
  folder_id      = var.folder_id
  description    = "Daily snapshot for web-1"

  schedule_policy {
    expression = "0 2 * * *"
  }

  snapshot_count = 7

  disk_ids = [
    yandex_compute_instance.web-1.boot_disk[0].disk_id
  ]
}

# Для web-2
resource "yandex_compute_snapshot_schedule" "web-2-schedule" {
  name           = "web-2-daily-snapshot"
  folder_id      = var.folder_id
  description    = "Daily snapshot for web-2"

  schedule_policy {
    expression = "0 2 * * *"
  }

  snapshot_count = 7

  disk_ids = [
    yandex_compute_instance.web-2.boot_disk[0].disk_id
  ]
}

# Для elasticsearch
resource "yandex_compute_snapshot_schedule" "elasticsearch-schedule" {
  name           = "elasticsearch-daily-snapshot"
  folder_id      = var.folder_id
  description    = "Daily snapshot for elasticsearch"

  schedule_policy {
    expression = "0 2 * * *"
  }

  snapshot_count = 7

  disk_ids = [
    yandex_compute_instance.elasticsearch.boot_disk[0].disk_id
  ]
}

# Для zabbix
resource "yandex_compute_snapshot_schedule" "zabbix-schedule" {
  name           = "zabbix-daily-snapshot"
  folder_id      = var.folder_id
  description    = "Daily snapshot for zabbix"

  schedule_policy {
    expression = "0 2 * * *"
  }

  snapshot_count = 7

  disk_ids = [
    yandex_compute_instance.zabbix.boot_disk[0].disk_id
  ]
}

# Для kibana
resource "yandex_compute_snapshot_schedule" "kibana-schedule" {
  name           = "kibana-daily-snapshot"
  folder_id      = var.folder_id
  description    = "Daily snapshot for kibana"

  schedule_policy {
    expression = "0 2 * * *"
  }

  snapshot_count = 7

  disk_ids = [
    yandex_compute_instance.kibana.boot_disk[0].disk_id
  ]
}

# Для bastion
resource "yandex_compute_snapshot_schedule" "bastion-schedule" {
  name           = "bastion-daily-snapshot"
  folder_id      = var.folder_id
  description    = "Daily snapshot for bastion"

  schedule_policy {
    expression = "0 2 * * *"
  }

  snapshot_count = 7

  disk_ids = [
    yandex_compute_instance.bastion.boot_disk[0].disk_id
  ]
}
