# Генерация SSH-ключа (если нет)
locals {
  ssh_public_key = file(pathexpand(var.ssh_public_key_path))
}

# Bastion Host
resource "yandex_compute_instance" "bastion" {
  allow_stopping_for_update = true
  name        = "bastion"
  hostname    = "bastion"
  zone        = var.zones[0]
  platform_id = "standard-v3"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8kdq6d0p8sij7h5qe3" # Ubuntu 22.04 LTS
      size     = 10
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public-subnet.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.bastion-sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${local.ssh_public_key}"
  }

  scheduling_policy {
    preemptible = var.preemptible
  }
}

# Web Server 1 (zone A)
resource "yandex_compute_instance" "web-1" {
  allow_stopping_for_update = true
  name        = "web-1"
  hostname    = "web-1"
  zone        = var.zones[0]
  platform_id = "standard-v3"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8kdq6d0p8sij7h5qe3"
      size     = 10
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private-subnet-a.id
    security_group_ids = [yandex_vpc_security_group.web-sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${local.ssh_public_key}"
  }

  scheduling_policy {
    preemptible = var.preemptible
  }
}

# Web Server 2 (zone B)
resource "yandex_compute_instance" "web-2" {
  allow_stopping_for_update = true
  name        = "web-2"
  hostname    = "web-2"
  zone        = var.zones[1]
  platform_id = "standard-v3"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8kdq6d0p8sij7h5qe3"
      size     = 10
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private-subnet-b.id
    security_group_ids = [yandex_vpc_security_group.web-sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${local.ssh_public_key}"
  }

  scheduling_policy {
    preemptible = var.preemptible
  }
}

# Zabbix Server
resource "yandex_compute_instance" "zabbix" {
  allow_stopping_for_update = true
  name        = "zabbix"
  hostname    = "zabbix"
  zone        = var.zones[0]
  platform_id = "standard-v3"

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8kdq6d0p8sij7h5qe3"
      size     = 20
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public-subnet.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.zabbix-sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${local.ssh_public_key}"
  }

  scheduling_policy {
    preemptible = var.preemptible
  }
}

# Elasticsearch Server
resource "yandex_compute_instance" "elasticsearch" {
  allow_stopping_for_update = true
  name        = "elasticsearch"
  hostname    = "elasticsearch"
  zone        = var.zones[0]
  platform_id = "standard-v3"

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8kdq6d0p8sij7h5qe3"
      size     = 20
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private-subnet-a.id
    security_group_ids = [yandex_vpc_security_group.elasticsearch-sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${local.ssh_public_key}"
  }

  scheduling_policy {
    preemptible = var.preemptible
  }
}

# Kibana Server
resource "yandex_compute_instance" "kibana" {
  allow_stopping_for_update = true
  name        = "kibana"
  hostname    = "kibana"
  zone        = var.zones[0]
  platform_id = "standard-v3"

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8kdq6d0p8sij7h5qe3"
      size     = 10
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public-subnet.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.kibana-sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${local.ssh_public_key}"
  }

  scheduling_policy {
    preemptible = var.preemptible
  }
}
