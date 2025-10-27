# VPC
resource "yandex_vpc_network" "diplom-network" {
  name        = "diplom-network"
  description = "Network for diploma project"
}

# Публичная подсеть для bastion, zabbix, kibana, ALB
resource "yandex_vpc_subnet" "public-subnet" {
  name           = "public-subnet"
  zone           = var.zones[0]
  network_id     = yandex_vpc_network.diplom-network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

# Приватная подсеть в зоне A для web-1, elasticsearch
resource "yandex_vpc_subnet" "private-subnet-a" {
  name           = "private-subnet-a"
  zone           = var.zones[0]
  network_id     = yandex_vpc_network.diplom-network.id
  v4_cidr_blocks = ["192.168.20.0/24"]
  route_table_id = yandex_vpc_route_table.private-route.id
}

# Приватная подсеть в зоне B для web-2
resource "yandex_vpc_subnet" "private-subnet-b" {
  name           = "private-subnet-b"
  zone           = var.zones[1]
  network_id     = yandex_vpc_network.diplom-network.id
  v4_cidr_blocks = ["192.168.30.0/24"]
  route_table_id = yandex_vpc_route_table.private-route.id
}

# NAT-шлюз для исходящего трафика из приватных подсетей
resource "yandex_vpc_gateway" "nat-gateway" {
  name = "nat-gateway"
  shared_egress_gateway {}
}

# Таблица маршрутизации для приватных подсетей
resource "yandex_vpc_route_table" "private-route" {
  name       = "private-route"
  network_id = yandex_vpc_network.diplom-network.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat-gateway.id
  }
}
