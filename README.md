# Дипломная работа: Отказоустойчивая инфраструктура в Yandex Cloud

## Описание

Данный проект реализует полнофункциональную отказоустойчивую инфраструктуру для веб-сайта в Yandex Cloud с:
- Load Balancing
- Мониторингом (Zabbix)
- Логированием (Elasticsearch + Kibana)
- Резервным копированием (Snapshot Schedule)

## 🚀 Развертывание и настройка серверов: Terraform + Ansible

### Двухэтапный процесс

Инфраструктура развертывается в **два этапа** с полной автоматизацией:

#### Этап 1: Terraform создает инфраструктуру в Yandex Cloud

```bash
cd terraform/
terraform init
terraform apply -auto-approve
```

**Terraform создает:**
- VPC Network с публичными и приватными подсетями
- 6 виртуальных машин (Bastion, Web-1, Web-2, Zabbix, Elasticsearch, Kibana)
- Application Load Balancer для распределения трафика
- Security Groups для безопасности
- Snapshot Schedule для резервного копирования

#### Этап 2: Ansible конфигурирует все сервисы

После создания ВМ, Terraform **автоматически** запускает Ansible:

**Фаза 1:** Common Configuration (все серверы)
**Фаза 2:** Web Servers (Nginx + Zabbix Agent)
**Фаза 3:** Monitoring (Zabbix Server)
**Фаза 4:** Logging (Elasticsearch + Kibana)
**Фаза 5:** Integration (регистрация в Zabbix)

### Как это работает

1. `terraform apply` создает все ВМ в облаке
2. Terraform генерирует `ansible/inventory/hosts.yml`
3. Terraform генерирует `ansible/ssh.config`
4. Terraform запускает `ansible-playbook` автоматически
5. Ansible конфигурирует 5 фаз
6. **Результат:** полностью готовая инфраструктура

### Проверка развертывания

```bash
terraform output
cd ../ansible
ansible all -i inventory/hosts.yml -m ping
ssh -F ssh.config web-1
curl http://localhost
```

### Документация по развертыванию

- **[server-provisioning.md](server-provisioning.md)** - Архитектура
- **[ansible-roles.md](ansible-roles.md)** - Роли
- **[quick-start.md](quick-start.md)** - Инструкции
- **[implementation-guide.md](implementation-guide.md)** - Руководство

### Решение замечания проверяющего

**Замечание:** "Не нашел как вы настраиваете сервера (производите развертывания)"

**Решение:**
1. ✅ provisioning.tf - запускает Ansible
2. ✅ playbooks/site.yml - 5 фаз конфигурирования
3. ✅ roles/ - установка пакетов
4. ✅ server-provisioning.md - полная архитектура
5. ✅ quick-start.md - пошаговый старт

---

## 📊 Доказательства

### Terraform Output
![Terraform Output](screenshots/01-terraform-output.png)

### ВМ в статусе RUNNING
![VMs Running](screenshots/02-vms-running.png)

### Zabbix Dashboard
![Zabbix Dashboard](screenshots/03-zabbix-dashboard.png)

### Kibana Dashboard
![Kibana Dashboard](screenshots/04-kibana-dashboard.png)

### Security Groups
![Security Groups](screenshots/05-security-groups.png)

### Snapshot Schedules
![Snapshot Schedules](screenshots/06-snapshot-schedules.png)

### GitHub Repository
![GitHub Repo](screenshots/07-github-repo.png)

### Bastion SSH Access
![Bastion SSH](screenshots/08-bastion-ssh.png)

## Архитектура

### Сеть
- **VPC Network**: diplom-network
- **Публичная подсеть**: public-subnet
- **Приватные подсети**: private-subnet-a, private-subnet-b
- **NAT Gateway**: для исходящего интернета из приватных сетей
- **Bastion Host**: для доступа к приватным ВМ через SSH

### Веб-серверы
- **web-1** (192.168.20.21) - Nginx в приватной сети зоны A
- **web-2** (192.168.30.27) - Nginx в приватной сети зоны B
- **Load Balancer**: Application Load Balancer для распределения трафика

### Мониторинг
- **Zabbix Server** (158.160.127.151) - в публичной сети
- **Zabbix Agents** - на web-1 и web-2
- Дашборды с метриками CPU, RAM, диски, сеть, HTTP

### Логирование
- **Elasticsearch** (192.168.20.9) - в приватной сети
- **Kibana** (158.160.124.158) - в публичной сети

### Резервное копирование
- **Snapshot Schedule** для всех ВМ
- Ежедневное копирование в 2:00 AM UTC
- Хранение 7 снимков (1 неделя)

## Развертывание

### Требования
- Terraform >= 1.0
- Yandex Cloud CLI
- SSH ключ для доступа

### Шаги развертывания

```bash
cd terraform/
terraform init
terraform apply -auto-approve
terraform output
```

## Доступ к сервисам

| Сервис | URL | Логин | Пароль |
|--------|-----|-------|--------|
| Zabbix | http://158.160.127.151 | admin | zabbix |
| Kibana | http://158.160.124.158:5601 | - | - |
| Веб | http://<alb_ip> | - | - |

### Bastion Host

SSH доступ:
```bash
ssh -i ~/.ssh/id_rsa ubuntu@158.160.55.35
```

SSH через бастион к web-1:
```bash
ssh -i ~/.ssh/id_rsa -o "ProxyCommand=ssh -i ~/.ssh/id_rsa -W %h:%p ubuntu@158.160.55.35" ubuntu@192.168.20.21
```

## Файлы Terraform

- `main.tf` - основная конфигурация
- `instances.tf` - определение ВМ
- `alb.tf` - Load Balancer
- `snapshots.tf` - расписание резервирования
- `provisioning.tf` - интеграция с Ansible ← Ключевой файл
- `variables.tf` - переменные

## Требования задания - ВЫПОЛНЕНО ✅

### Инфраструктура
✅ Terraform для развёртки
✅ VPC Network с публичными и приватными сетями
✅ Bastion Host
✅ NAT Gateway

### Веб-сайт
✅ Две ВМ в разных зонах (web-1, web-2)
✅ Nginx установлен
✅ Приватные сети
✅ Доступ через Bastion SSH
✅ Load Balancer

### Мониторинг
✅ Zabbix Server
✅ Zabbix Agents
✅ Дашборды

### Логирование
✅ Elasticsearch
✅ Kibana

### Резервное копирование
✅ Snapshot Schedule

### Развертывание и настройка серверов ✅ НОВОЕ
✅ Terraform создает инфраструктуру
✅ Ansible конфигурирует все сервисы (5 фаз)
✅ Полная документация
✅ Всё автоматизировано

## Выходные данные Terraform

```
bastion_public_ip = "158.160.55.35"
elasticsearch_private_ip = "192.168.20.9"
kibana_public_ip = "158.160.124.158"
web-1_private_ip = "192.168.20.21"
web-2_private_ip = "192.168.30.27"
zabbix_public_ip = "158.160.127.151"
```

## Примечания

- Filebeat не установлен из-за ограничений доступа к внешним сетям
- ALB имеет баг в провайдере Terraform (endpoint остается null, но работает)

## Стоимость

Минимальные конфигурации:
- 2 ядра, 20% Intel Ice Lake
- 2-4 Гб памяти
- 10 Гб SSD
- Прерываемые ВМ

## Автор

Николай Зарубов
nvzarubov@gmail.com
