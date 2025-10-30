# 🏗️ Развертывание и настройка серверов: Terraform + Ansible

## 📋 Обзор

Данный документ описывает процесс **автоматизированного развертывания и настройки серверов** в дипломной работе "Отказоустойчивая инфраструктура в Yandex Cloud" с использованием:

- **Terraform** - Infrastructure as Code для создания облачной инфраструктуры
- **Ansible** - Configuration Management для автоматического конфигурирования серверов


Этот документ полностью описывает как это работает.

## 🏗️ Архитектура развертывания

### Общая схема

```
┌─────────────────────────────────────────────────────┐
│          TERRAFORM PHASE                            │
│  (Infrastructure as Code)                           │
├─────────────────────────────────────────────────────┤
│                                                     │
│  1. terraform init    → Инициализация              │
│  2. terraform plan    → Планирование               │
│  3. terraform apply   → Создание ресурсов          │
│                                                     │
│  Создает в Yandex Cloud:                           │
│  ├─ VPC Network (10.0.0.0/16)                     │
│  ├─ Public Subnet (192.168.10.0/24)               │
│  ├─ Private Subnets (192.168.20.0/24, 30.0/24)    │
│  ├─ Security Groups (5 штук)                      │
│  ├─ 6 Compute Instances                           │
│  ├─ Application Load Balancer                      │
│  ├─ NAT Gateway                                    │
│  └─ Snapshot Schedule                             │
│                                                     │
│  4. Генерирует ansible/inventory/hosts.yml         │
│  5. Генерирует ansible/ssh.config                  │
│  6. Запускает Ansible provisioner                  │
│                                                     │
└────────────────┬────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────────┐
│          ANSIBLE PHASE                              │
│  (Configuration Management)                         │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Выполняет 5 фаз конфигурирования:                 │
│                                                     │
│  Фаза 1: Common Configuration (все серверы)       │
│  │                                                 │
│  ├─ wait_for_connection (ждет готовности)        │
│  ├─ apt update                                     │
│  ├─ install base packages                         │
│  ├─ setup timezone (Europe/Moscow)                │
│  ├─ setup system limits                           │
│  └─ enable firewall (ufw)                         │
│                                                     │
│  Фаза 2: Web Servers (web-1, web-2)              │
│  │                                                 │
│  ├─ install nginx                                 │
│  ├─ create health check page                      │
│  ├─ install zabbix-agent                         │
│  ├─ configure zabbix connection                   │
│  ├─ open ports 80, 443                           │
│  └─ start all services                           │
│                                                     │
│  Фаза 3: Monitoring (zabbix-server)              │
│  │                                                 │
│  ├─ install mysql-server                         │
│  ├─ install zabbix-server-mysql                  │
│  ├─ create zabbix database                       │
│  ├─ setup web interface                          │
│  └─ start services                               │
│                                                     │
│  Фаза 4: Logging (elasticsearch + kibana)        │
│  │                                                 │
│  ├─ install java                                 │
│  ├─ install elasticsearch                        │
│  ├─ install kibana                               │
│  ├─ configure cluster                            │
│  ├─ create index templates                       │
│  └─ start services                               │
│                                                     │
│  Фаза 5: Integration                             │
│  │                                                 │
│  ├─ register servers in zabbix                   │
│  ├─ setup metric collection                      │
│  └─ verify connectivity                          │
│                                                     │
│  Результат:                                       │
│  ✓ Все сервисы установлены и работают            │
│  ✓ Мониторинг активен                            │
│  ✓ Логирование работает                          │
│  ✓ Балансировка готова                           │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## 📁 Структура проекта

```
sys-diplom-terraform/
│
├── terraform/
│   ├── main.tf                     # VPC, подсети, Security Groups
│   ├── instances.tf                # Определение всех ВМ
│   ├── alb.tf                      # Application Load Balancer
│   ├── snapshots.tf                # Snapshot Schedule для резервирования
│   ├── variables.tf                # Переменные Terraform
│   ├── outputs.tf                  # Выходные данные (IP адреса, FQDN)
│   ├── provisioning.tf             # ✨ НОВОЕ: Интеграция с Ansible
│   ├── templates/
│   │   ├── inventory.tpl           # ✨ НОВОЕ: Шаблон Ansible inventory
│   │   └── ssh_config.tpl          # ✨ НОВОЕ: SSH конфиг для Bastion
│   └── terraform.tfvars            # Значения переменных (ваши)
│
├── ansible/
│   ├── ansible.cfg                 # Конфигурация Ansible
│   ├── ssh.config                  # Генерируется Terraform
│   │
│   ├── inventory/
│   │   └── hosts.yml               # Динамический инвентарь (генерируется Terraform)
│   │
│   ├── playbooks/
│   │   ├── site.yml                # Главный playbook со всеми 5 фазами
│   │   ├── webservers.yml          # Настройка веб-серверов
│   │   ├── monitoring.yml          # Настройка Zabbix
│   │   └── logging.yml             # Настройка ELK Stack
│   │
│   ├── roles/
│   │   ├── common/
│   │   │   ├── tasks/main.yml      # Базовая конфигурация
│   │   │   ├── handlers/
│   │   │   └── templates/
│   │   │
│   │   ├── nginx/
│   │   │   ├── tasks/main.yml      # Установка Nginx
│   │   │   ├── templates/
│   │   │   └── handlers/
│   │   │
│   │   ├── zabbix-agent/
│   │   │   ├── tasks/main.yml      # Установка Zabbix Agent
│   │   │   └── templates/
│   │   │
│   │   └── elasticsearch/
│   │       ├── tasks/main.yml      # Установка Elasticsearch + Kibana
│   │       └── templates/
│   │
│   └── group_vars/
│       ├── all.yml                 # Переменные для всех хостов
│       ├── webservers.yml          # Переменные для веб-серверов
│       └── monitoring.yml          # Переменные для мониторинга
│
├── quick-start.md                  # Пошаговые инструкции
├── server-provisioning.md          # Этот файл - Архитектура
├── ansible-roles.md                # Описание ролей
├── implementation-guide.md         # Полное руководство
│
└── README.md
```

## 🌐 Сетевая топология

```
┌────────────────────────────────────────────────────────────┐
│                        INTERNET                            │
└────────────────┬───────────────────────────────────────────┘
                 │
        ┌────────┴────────┐
        │                 │
   ┌────▼──────┐    ┌────▼──────────┐
   │  Bastion  │    │ Kibana        │
   │(Public)   │    │(Public)       │
   │158.160... │    │158.160.124... │
   └────┬──────┘    └────┬──────────┘
        │                │
   ┌────┴────────────────┴──────────────────┐
   │                                        │
   │        VPC Network (10.0.0.0/16)      │
   │                                        │
   │  ┌─────────────────────────────────┐  │
   │  │  Public Subnet                  │  │
   │  │  192.168.10.0/24                │  │
   │  │                                 │  │
   │  │  ┌──────────────────────────┐   │  │
   │  │  │  Zabbix Server          │   │  │
   │  │  │  158.160.127.151        │   │  │
   │  │  │  (мониторинг)           │   │  │
   │  │  └──────────────────────────┘   │  │
   │  └─────────────────────────────────┘  │
   │                                        │
   │  ┌─────────────────────────────────┐  │
   │  │  Private Subnet A (Zone a)      │  │
   │  │  192.168.20.0/24                │  │
   │  │                                 │  │
   │  │  ┌──────────────────────────┐   │  │
   │  │  │  web-1 (Nginx + Agent)  │   │  │
   │  │  │  192.168.20.21          │   │  │
   │  │  └──────────────────────────┘   │  │
   │  │                                 │  │
   │  │  ┌──────────────────────────┐   │  │
   │  │  │  Elasticsearch          │   │  │
   │  │  │  192.168.20.9           │   │  │
   │  │  │  (логирование)          │   │  │
   │  │  └──────────────────────────┘   │  │
   │  │                                 │  │
   │  └─────────────────────────────────┘  │
   │                                        │
   │  ┌─────────────────────────────────┐  │
   │  │  Private Subnet B (Zone b)      │  │
   │  │  192.168.30.0/24                │  │
   │  │                                 │  │
   │  │  ┌──────────────────────────┐   │  │
   │  │  │  web-2 (Nginx + Agent)  │   │  │
   │  │  │  192.168.30.27          │   │  │
   │  │  └──────────────────────────┘   │  │
   │  │                                 │  │
   │  └─────────────────────────────────┘  │
   │                                        │
   │  ┌─────────────────────────────────┐  │
   │  │  Application Load Balancer      │  │
   │  │  Распределяет трафик:           │  │
   │  │  50% → web-1                    │  │
   │  │  50% → web-2                    │  │
   │  │  Health check: / (port 80)     │  │
   │  └─────────────────────────────────┘  │
   │                                        │
   └────────────────────────────────────────┘
```

## 📊 Выходные данные Terraform

После развертывания `terraform apply` вы получите:

```
Базовая инфраструктура:
  alb_external_ip = "ip.ip.ip.ip"  (Load Balancer)
  nat_gateway_ip = "ip.ip.ip.ip"   (NAT для приватных сетей)

Bastion Host (точка входа):
  bastion_public_ip = "158.160.55.35"
  bastion_fqdn = "bastion.ru-central1.internal"

Веб-серверы (в приватной сети, доступны через Bastion):
  web-1_private_ip = "192.168.20.21"
  web-1_fqdn = "web-1.ru-central1.internal"
  web-2_private_ip = "192.168.30.27"
  web-2_fqdn = "web-2.ru-central1.internal"

Мониторинг (Zabbix):
  zabbix_public_ip = "158.160.127.151"
  zabbix_fqdn = "zabbix.ru-central1.internal"

Логирование (ELK Stack):
  elasticsearch_private_ip = "192.168.20.9"
  elasticsearch_fqdn = "elasticsearch.ru-central1.internal"
  kibana_public_ip = "158.160.124.158"
  kibana_fqdn = "kibana.ru-central1.internal"
```

Получить эти данные:
```bash
terraform output
```

## ✅ Результат после развертывания

**Полностью готовая отказоустойчивая инфраструктура:**

- ✓ **Сеть:** VPC с публичными и приватными подсетями, NAT Gateway
- ✓ **Безопасность:** Security Groups для каждого типа сервера
- ✓ **Веб-серверы:** 2 ВМ с Nginx за Load Balancer
- ✓ **Мониторинг:** Zabbix Server собирает метрики всех компонентов
- ✓ **Агенты:** Zabbix Agents на всех ВМ отправляют метрики
- ✓ **Логирование:** Elasticsearch собирает логи всех компонентов
- ✓ **Визуализация:** Kibana показывает логи в веб-интерфейсе
- ✓ **Балансировка:** Application Load Balancer распределяет трафик
- ✓ **Резервирование:** Snapshot Schedule создает ежедневные снапшоты
- ✓ **SSH доступ:** Bastion Host для безопасного доступа к приватным ВМ

## 🔍 Проверка работоспособности

### 1. Получить все IP адреса

```bash
cd terraform/
terraform output
```

### 2. Проверить доступность всех серверов

```bash
cd ../ansible
ansible all -i inventory/hosts.yml -m ping
```

Все должны ответить **SUCCESS** (зеленый цвет).

### 3. SSH доступ к серверам

```bash
# Подключиться к Bastion
ssh -F ssh.config bastion

# Подключиться к web-1 через Bastion
ssh -F ssh.config web-1

# Проверить что Nginx работает
curl http://localhost

# Проверить Zabbix Agent
sudo systemctl status zabbix-agent

# Выход
exit
```

### 4. Открыть веб-интерфейсы в браузере

**Zabbix (мониторинг):**
```
URL: http://158.160.127.151
Логин: admin
Пароль: zabbix

Должны быть видны все хосты со статусом "Available"
```

**Kibana (логирование):**
```
URL: http://158.160.124.158:5601

Должны быть индексы логов и информация о сервисах
```

**Веб-сайт (через Load Balancer):**
```
URL: http://<alb_external_ip>

Должна быть HTML страница с информацией о сервере
```

## 📚 Связанная документация

- **[quick-start.md](quick-start.md)** - Пошаговые инструкции для быстрого развертывания
- **[ansible-roles.md](ansible-roles.md)** - Подробное описание каждой Ansible роли
- **[implementation-guide.md](implementation-guide.md)** - Полное руководство по реализации

---

**Решение:**

1. ✅ **provisioning.tf** - показывает как Terraform запускает Ansible
2. ✅ **templates/inventory.tpl** - показывает как генерируется конфигурация
3. ✅ **Ansible playbooks** - показывают 5 фаз конфигурирования
4. ✅ **Ansible roles** - показывают какие пакеты устанавливаются
5. ✅ **Этот документ** - объясняет всю архитектуру и процесс
6. ✅ **quick-start.md** - показывает как запустить развертывание
7. ✅ **implementation-guide.md** - показывает детали реализации

---

**Автор:** Николай Зарубов  
**Email:** nvzarubov@gmail.com

**Теперь полностью понятна архитектура развертывания и настройки инфраструктуры!** ✅
