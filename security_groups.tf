# Security Group для Bastion (только SSH)
resource "yandex_vpc_security_group" "bastion-sg" {
  name        = "bastion-sg"
  description = "Security group for bastion host"
  network_id  = yandex_vpc_network.diplom-network.id

  ingress {
    protocol       = "TCP"
    description    = "Allow SSH"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outgoing traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group для Web-серверов
resource "yandex_vpc_security_group" "web-sg" {
  name        = "web-sg"
  description = "Security group for web servers"
  network_id  = yandex_vpc_network.diplom-network.id

  ingress {
    protocol       = "TCP"
    description    = "Allow SSH from bastion"
    security_group_id = yandex_vpc_security_group.bastion-sg.id
    port           = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "Allow HTTP from ALB"
    v4_cidr_blocks = ["192.168.10.0/24"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "Allow Zabbix agent"
    security_group_id = yandex_vpc_security_group.zabbix-sg.id
    port           = 10050
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outgoing traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group для Zabbix
resource "yandex_vpc_security_group" "zabbix-sg" {
  name        = "zabbix-sg"
  description = "Security group for Zabbix server"
  network_id  = yandex_vpc_network.diplom-network.id

  ingress {
    protocol       = "TCP"
    description    = "Allow SSH from bastion"
    security_group_id = yandex_vpc_security_group.bastion-sg.id
    port           = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "Allow Zabbix web interface"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "Allow Zabbix agents"
    v4_cidr_blocks = ["192.168.0.0/16"]
    port           = 10051
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outgoing traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group для Elasticsearch
resource "yandex_vpc_security_group" "elasticsearch-sg" {
  name        = "elasticsearch-sg"
  description = "Security group for Elasticsearch"
  network_id  = yandex_vpc_network.diplom-network.id

  ingress {
    protocol       = "TCP"
    description    = "Allow SSH from bastion"
    security_group_id = yandex_vpc_security_group.bastion-sg.id
    port           = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "Allow Elasticsearch API"
    v4_cidr_blocks = ["192.168.0.0/16"]
    port           = 9200
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outgoing traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group для Kibana
resource "yandex_vpc_security_group" "kibana-sg" {
  name        = "kibana-sg"
  description = "Security group for Kibana"
  network_id  = yandex_vpc_network.diplom-network.id

  ingress {
    protocol       = "TCP"
    description    = "Allow SSH from bastion"
    security_group_id = yandex_vpc_security_group.bastion-sg.id
    port           = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "Allow Kibana web interface"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 5601
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outgoing traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
