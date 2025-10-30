# 📝 Руководство по развертыванию: Terraform + Ansible 

- ✅ **Terraform** для создания инфраструктуры в Yandex Cloud
- ✅ **Ansible** для конфигурирования всех сервисов
- ✅ **Полная документация** процесса развертывания

## 🏗️ Полный процесс развертывания

### Этап 1: Подготовка

**Установка инструментов:**
```bash
# Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Ansible
sudo apt-add-repository ppa:ansible/ansible -y
sudo apt update
sudo apt install ansible -y

# Yandex Cloud CLI
curl https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
```

**Подготовка учетных данных:**
```bash
# SSH ключи
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# Yandex Cloud токен
yc auth login
yc iam service-account create --name terraform-sa
yc iam service-account add-access-binding terraform-sa --role roles/editor
yc iam create-token --service-account-name terraform-sa

# Cloud и Folder ID
yc config list
```

**Создание terraform.tfvars:**
```bash
cd ~/sys-diplom-terraform/terraform/
cat > terraform.tfvars << 'EOF'
yc_token      = "t1.9euelZrO8Z..."
yc_cloud_id   = "b1g1234567890abc"
yc_folder_id  = "b1g0987654321xyz"
yc_zone       = "ru-central1-a"

public_key_path  = "~/.ssh/id_rsa.pub"
private_key_path = "~/.ssh/id_rsa"

web_servers_count = 2
vm_cores          = 2
vm_memory         = 4
core_fraction     = 20
preemptible       = true
EOF
```

### Этап 2: Terraform - Создание инфраструктуры

**Инициализация Terraform:**
```bash
terraform init
```

Загружает:
- Yandex Cloud провайдер
- Все необходимые модули
- Инициализирует backend

**Проверка плана:**
```bash
terraform plan
```

Показывает что будет создано:
- VPC Network: `diplom-network`
- Подсети: `public-subnet`, `private-subnet-a`, `private-subnet-b`
- Security Groups для каждого типа сервера
- 6 ВМ: Bastion, Web-1, Web-2, Zabbix, Elasticsearch, Kibana
- Application Load Balancer для распределения трафика
- Snapshot Schedule для резервного копирования

**Развертывание:**
```bash
terraform apply -auto-approve
```

Создает все ресурсы в Yandex Cloud (5-10 минут).

**Выходные данные:**
```
bastion_public_ip = "158.160.55.35"
elasticsearch_private_ip = "192.168.20.9"
kibana_public_ip = "158.160.124.158"
web-1_fqdn = "web-1.ru-central1.internal"
web-1_private_ip = "192.168.20.21"
web-2_fqdn = "web-2.ru-central1.internal"
web-2_private_ip = "192.168.30.27"
zabbix_public_ip = "158.160.127.151"
```

### Этап 3: Terraform - Генерация Ansible конфигурации

После создания ВМ, Terraform **автоматически**:

1. **Читает информацию о созданных ВМ** (IP адреса, FQDN)
2. **Генерирует** `ansible/inventory/hosts.yml` из шаблона `templates/inventory.tpl`
3. **Генерирует** `ansible/ssh.config` из шаблона `templates/ssh_config.tpl`
4. **Запускает** Ansible provisioner

**Файл inventory.tpl (шаблон):**
```yaml
all:
  vars:
    ansible_user: ubuntu
    ansible_python_interpreter: /usr/bin/python3
  children:
    bastion:
      hosts:
        bastion:
          ansible_host: "${bastion_ip}"
    webservers:
      hosts:
        web-1:
          ansible_host: "${web_1_ip}"
        web-2:
          ansible_host: "${web_2_ip}"
    monitoring:
      hosts:
        zabbix-server:
          ansible_host: "${zabbix_ip}"
    logging:
      hosts:
        kibana:
          ansible_host: "${kibana_ip}"
    elasticsearch_servers:
      hosts:
        elasticsearch:
          ansible_host: "${elasticsearch_ip}"
```

**Генерируемый hosts.yml (пример):**
```yaml
all:
  vars:
    ansible_user: ubuntu
  children:
    webservers:
      hosts:
        web-1:
          ansible_host: 192.168.20.21
        web-2:
          ansible_host: 192.168.30.27
    # ... и т.д.
```

### Этап 4: Terraform - Запуск Ansible

**Файл provisioning.tf запускает:**
```bash
ansible-playbook playbooks/site.yml -i inventory/hosts.yml -v
```

Это происходит **автоматически** как часть `terraform apply`.

### Этап 5: Ansible - Конфигурирование 5 фаз

**Фаза 1: Common Configuration** (все серверы)

Playbook: `playbooks/site.yml` (первая часть)

```yaml
- name: Common configuration
  hosts: all
  become: yes
  tasks:
    - name: Wait for system
      wait_for_connection:
        delay: 10
        timeout: 300
    
    - name: Update apt cache
      apt:
        update_cache: yes
    
    - name: Install packages
      apt:
        name: [python3-pip, git, curl, wget, vim, htop, net-tools]
```

Результат:
- ✓ Все серверы обновлены
- ✓ Базовые пакеты установлены
- ✓ Python готов для Ansible

**Фаза 2: Web Servers** (web-1, web-2)

Role: `roles/nginx` и `roles/zabbix-agent`

```yaml
- name: Configure web servers
  hosts: webservers
  become: yes
  roles:
    - nginx
    - zabbix-agent
  tasks:
    - name: Create health check page
      copy:
        content: |
          <!DOCTYPE html>
          <h1>Server: {{ inventory_hostname }}</h1>
        dest: /var/www/html/index.html
```

Результат:
- ✓ Nginx установлен и работает
- ✓ Zabbix Agent отправляет метрики
- ✓ Health check страница работает
- ✓ Ports 80, 443 открыты в firewall

**Фаза 3: Monitoring** (zabbix-server)

```yaml
- name: Install Zabbix Server
  hosts: zabbix-server
  become: yes
  tasks:
    - name: Install MySQL
      apt:
        name: mysql-server
    
    - name: Install Zabbix Server
      apt:
        name: zabbix-server-mysql
    
    - name: Configure database
      # ... SQL commands ...
    
    - name: Start services
      service:
        name: "{{ item }}"
        state: started
        enabled: yes
      with_items: [mysql, zabbix-server]
```

Результат:
- ✓ MySQL готов к работе
- ✓ Zabbix Server установлен
- ✓ Веб-интерфейс доступен
- ✓ База данных инициализирована

**Фаза 4: Logging** (elasticsearch + kibana)

Role: `roles/elasticsearch`

```yaml
- name: Install Elasticsearch
  hosts: elasticsearch_servers
  become: yes
  tasks:
    - name: Install Java
      apt:
        name: openjdk-11-jre-headless
    
    - name: Install Elasticsearch
      apt:
        name: elasticsearch
    
    - name: Configure cluster
      # ... elasticsearch.yml ...
    
    - name: Start service
      service:
        name: elasticsearch
        state: started
```

На kibana:
```yaml
- name: Install Kibana
  hosts: kibana
  become: yes
  tasks:
    - name: Install Kibana
      apt:
        name: kibana
    
    - name: Configure Elasticsearch connection
      # ... kibana.yml ...
    
    - name: Start service
      service:
        name: kibana
        state: started
```

Результат:
- ✓ Elasticsearch собирает логи
- ✓ Kibana визуализирует логи
- ✓ Оба сервиса работают
- ✓ Связь между ними установлена

**Фаза 5: Integration**

```yaml
- name: Register servers in Zabbix
  hosts: zabbix-server
  become: yes
  tasks:
    - name: Add web servers to Zabbix
      # ... API calls ...
    
    - name: Configure metric collection
      # ... Custom metrics ...
    
    - name: Verify connectivity
      # ... Health checks ...
```

Результат:
- ✓ Web-1 и Web-2 видны в Zabbix
- ✓ Zabbix собирает метрики (CPU, RAM, диски, сеть, HTTP)
- ✓ Все системы интегрированы

## 🔄 Полный цикл

```
1. terraform init
   ↓
2. terraform apply
   ├─ Создает инфраструктуру (5 мин)
   ├─ Генерирует inventory
   ├─ Генерирует ssh.config
   └─ Запускает Ansible
   ↓
3. Ansible Фаза 1-5 (5 мин)
   ├─ Common на всех серверах
   ├─ Nginx на web-1, web-2
   ├─ Zabbix Server установлен
   ├─ Elasticsearch + Kibana готовы
   └─ Интеграция завершена
   ↓
4. terraform output
   ├─ Получить IP адреса
   └─ Оцените результат
```

## ✅ Проверка каждого этапа

**После Terraform:**
```bash
terraform show          # Посмотреть созданные ресурсы
terraform output        # Получить IP адреса
yc compute instance list  # Проверить ВМ в облаке
```

**После Ansible:**
```bash
cd ../ansible
ansible all -i inventory/hosts.yml -m ping  # Все серверы доступны?
cat ansible.log  # Логи выполнения

# Проверить каждый сервер
ssh -F ssh.config web-1
  curl http://localhost      # Nginx работает?
  systemctl status zabbix-agent  # Agent работает?
  exit

ssh -F ssh.config elasticsearch
  curl localhost:9200        # Elasticsearch работает?
  exit
```

**Веб-интерфейсы:**
```bash
# Zabbix
http://158.160.127.151
admin / zabbix
Должны быть 2 хоста со статусом "Available"

# Kibana
http://158.160.124.158:5601
Должны быть индексы логов

# Веб-сайт
http://<alb_ip>
Должна быть HTML страница
```

## 📊 Архитектура результата

```
┌─────────────────────────────────────────────┐
│         INTERNET                            │
├─────────────────────────────────────────────┤
│ ALB (Application Load Balancer)             │
│ Распределяет трафик: 50% web-1, 50% web-2  │
└────────────┬─────────────────────────────────┘
             │
    ┌────────┴────────┐
    │                 │
┌───▼──────┐    ┌────▼───────┐
│  web-1   │    │   web-2    │
│  Nginx   │    │   Nginx    │
│Zabbix AG │    │ Zabbix AG  │
│192.168.20│    │192.168.30. │
└────┬─────┘    └────┬───────┘
     │                │
     └────────┬───────┘
              │
      ┌───────▼────────┐
      │ Zabbix Server  │
      │Мониторит все   │
      │158.160.127.151 │
      └────────────────┘
      
      ┌───────────────────┐
      │ Elasticsearch     │
      │ Собирает логи     │
      │ 192.168.20.9      │
      └─────────┬─────────┘
                │
      ┌─────────▼─────────┐
      │ Kibana            │
      │ Визуализирует     │
      │ 158.160.124.158   │
      └───────────────────┘
```

## 📈 Результаты

**После полного развертывания вы имеете:**

- ✅ **Готовая инфраструктура** - 6 ВМ в Yandex Cloud
- ✅ **Веб-сайт** - 2 веб-сервера с Nginx за Load Balancer
- ✅ **Мониторинг** - Zabbix собирает метрики всех компонентов
- ✅ **Логирование** - Elasticsearch + Kibana для анализа логов
- ✅ **Безопасность** - Bastion Host для доступа к приватным ВМ
- ✅ **Резервирование** - Ежедневные снапшоты всех ВМ
- ✅ **Высокая доступность** - Балансировка нагрузки между веб-серверами

## 📝 Документы проекта

| Документ | Назначение |
|----------|-----------|
| **quick-start.md** | Пошаговые инструкции для быстрого развертывания |
| **server-provisioning.md** | Описание архитектуры развертывания и проверки |
| **ansible-roles.md** | Подробное описание каждой Ansible роли |
| **implementation-guide.md** | Этот файл - полное руководство по реализации |

## 🎓 Заключение

Эта реализация показывает:

1. **Infrastructure as Code** - вся инфраструктура описана в коде Terraform
2. **Configuration Management** - все настройки автоматизированы через Ansible
3. **Integration** - Terraform и Ansible работают вместе для полной автоматизации
4. **Scalability** - можно легко добавить больше веб-серверов, изменив переменную
5. **Reliability** - все компоненты мониторятся и логируются

---

**Автор:** Николай Зарубов  
**Email:** nvzarubov@gmail.com

**Полное руководство по развертыванию завершено!** ✅
