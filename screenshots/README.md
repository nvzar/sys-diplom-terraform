# Доказательства работающей инфраструктуры

## Текстовые выводы

### 01-terraform-outputs.txt

Содержит все IP адреса и ресурсы:
- bastion_public_ip = "158.160.55.35"
- elasticsearch_private_ip = "192.168.20.9"
- kibana_public_ip = "158.160.124.158"
- web-1_fqdn = "web-1.ru-central1.internal"
- web-1_private_ip = "192.168.20.21"
- web-2_fqdn = "web-2.ru-central1.internal"
- web-2_private_ip = "192.168.30.27"
- zabbix_public_ip = "158.160.127.151"

### 02-terraform-state.txt
Результат команды:


Список всех созданных ресурсов:
- yandex_alb_backend_group.web-bg
- yandex_alb_http_router.web-router
- yandex_alb_load_balancer.web-alb
- yandex_alb_target_group.web-tg
- yandex_alb_virtual_host.web-vh
- yandex_compute_instance.bastion
- yandex_compute_instance.elasticsearch
- yandex_compute_instance.kibana
- yandex_compute_instance.web-1
- yandex_compute_instance.web-2
- yandex_compute_instance.zabbix
- yandex_compute_snapshot_schedule.bastion-schedule
- yandex_compute_snapshot_schedule.elasticsearch-schedule
- yandex_compute_snapshot_schedule.kibana-schedule
- yandex_compute_snapshot_schedule.web-1-schedule
- yandex_compute_snapshot_schedule.web-2-schedule
- yandex_compute_snapshot_schedule.zabbix-schedule
- yandex_vpc_gateway.nat-gateway
- yandex_vpc_network.diplom-network
- yandex_vpc_route_table.private-route
- yandex_vpc_security_group.bastion-sg
- yandex_vpc_security_group.elasticsearch-sg
- yandex_vpc_security_group.kibana-sg
- yandex_vpc_security_group.web-sg
- yandex_vpc_security_group.zabbix-sg
- yandex_vpc_subnet.private-subnet-a
- yandex_vpc_subnet.private-subnet-b
- yandex_vpc_subnet.public-subnet

## Команды для проверки


### Все ВМ в статусе RUNNING
yc compute instance list

Результат:


+----------------------+---------------+---------------+---------+-----------------+---------------+
| ID | NAME | ZONE ID | STATUS | EXTERNAL IP | INTERNAL IP |
+----------------------+---------------+---------------+---------+-----------------+---------------+
| epdclars3lua3nii47c3 | web-2 | ru-central1-b | RUNNING | | 192.168.30.27 |
| fhm4hcc6ka8klhrjri2d | bastion | ru-central1-a | RUNNING | 158.160.55.35 | 192.168.10.18 |
| fhm8kt5lmvrimb9ptn26 | elasticsearch | ru-central1-a | RUNNING | | 192.168.20.9 |
| fhma2320acdockfus2j2 | zabbix | ru-central1-a | RUNNING | 158.160.127.151 | 192.168.10.16 |
| fhmp0e8nubii1qjpu7om | kibana | ru-central1-a | RUNNING | 158.160.124.158 | 192.168.10.9 |
| fhmvv7hh196rbbmtcj7m | web-1 | ru-central1-a | RUNNING | | 192.168.20.21 |
+----------------------+---------------+---------------+---------+-----------------+---------------+

### Security Groups (контроль доступа)

yc vpc security-group list

Результат: 6 расписаний для ежедневного резервного копирования

## ✅ Выполненные требования

✅ 6 ВМ созданы и работают (RUNNING)
✅ 28 Terraform ресурсов развернуто
✅ 6 Snapshot Schedules для резервного копирования (7 дней)
✅ Код загружен на GitHub
✅ Полная документация создана

## 📍 Ссылки на сервисы

- **Bastion Host**: ssh -i ~/.ssh/id_rsa ubuntu@158.160.55.35
- **Zabbix**: http://158.160.127.151
- **Kibana**: http://158.160.124.158:5601
- **Elasticsearch**: http://192.168.20.9:9200

## 📊 Архитектура

- **1 VPC** с публичной и приватными подсетями
- **6 ВМ**: bastion, web-1, web-2, elasticsearch, zabbix, kibana
- **1 Load Balancer** Application Load Balancer
- **6 Snapshot Schedules** для резервного копирования (хранение 7 дней)
- **5 Security Groups** для безопасности

