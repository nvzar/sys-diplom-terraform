# Информация о развернутой инфраструктуре

## 📍 IP адреса и доступ

### Bastion Host
- **IP**: 158.160.55.35
- **SSH**: ssh -i ~/.ssh/id_rsa ubuntu@158.160.55.35

### Zabbix (Мониторинг)
- **Публичный IP**: 158.160.127.151
- **URL**: http://158.160.127.151
- **Логин**: admin / Пароль: zabbix

### Kibana (Логирование)
- **Публичный IP**: 158.160.124.158
- **URL**: http://158.160.124.158:5601

### Elasticsearch
- **Внутренний IP**: 192.168.20.9:9200

### Web Servers
- **web-1**: 192.168.20.21 (зона A)
- **web-2**: 192.168.30.27 (зона B)

## ✅ Выполненные требования

✅ Terraform инфраструктура
✅ VPC с публичными/приватными сетями
✅ NAT Gateway
✅ Bastion Host
✅ 2 web-сервера с Nginx
✅ Application Load Balancer
✅ Zabbix мониторинг с Agents
✅ Elasticsearch + Kibana
✅ Snapshot Schedule (7 дней)
✅ Security Groups
✅ Документация

