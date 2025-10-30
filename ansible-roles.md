# 📦 Ansible Roles: Описание и использование

## 📋 Обзор

Документ описывает 4 Ansible роли для конфигурирования всех компонентов инфраструктуры.

Все роли **идемпотентны** - их можно запускать многократно без проблем.

## 🏗️ Роли проекта

```
ansible/roles/
├── common/              # Базовая конфигурация всех серверов
├── nginx/               # Установка и настройка Nginx
├── zabbix-agent/        # Установка Zabbix Agent
└── elasticsearch/       # Установка Elasticsearch + Kibana
```

---

## 🔧 Role: common

**Назначение:** Базовая конфигурация всех серверов

**Применяется к:** Все серверы (all)

**Что делает:**

1. Ожидает готовности системы
2. Обновляет apt cache
3. Обновляет пакеты системы
4. Устанавливает базовые пакеты:
   - python3-pip (Python для Ansible)
   - git (контроль версий)
   - curl, wget (загрузка файлов)
   - vim (редактор)
   - htop (мониторинг)
   - net-tools (сетевые утилиты)

5. Настраивает timezone на Europe/Moscow
6. Настраивает system limits
7. Включает firewall (ufw)

**Результат:**
- ✓ Система обновлена
- ✓ Базовые пакеты установлены
- ✓ Все серверы готовы

---

## 🌐 Role: nginx

**Назначение:** Установка и конфигурация веб-сервера

**Применяется к:** webservers группа (web-1, web-2)

**Что делает:**

1. Добавляет репозиторий Nginx
2. Устанавливает Nginx
3. Создает конфигурацию виртуального хоста
4. Развертывает health check страницу:
   ```html
   <h1>Server: web-1</h1>
   <p>Status: Running ✓</p>
   ```
   Используется Load Balancer для проверки доступности

5. Открывает ports 80 (HTTP) и 443 (HTTPS)
6. Запускает Nginx и включает автозагрузку

**Результат:**
- ✓ Nginx установлен и работает
- ✓ Ports 80, 443 открыты
- ✓ Health check доступна
- ✓ Load Balancer может проверять доступность

---

## 📊 Role: zabbix-agent

**Назначение:** Установка агента мониторинга

**Применяется к:** Все серверы с агентом (web-1, web-2, elasticsearch, bastion)

**Что делает:**

1. Добавляет репозиторий Zabbix
2. Устанавливает Zabbix Agent
3. Конфигурирует подключение к Zabbix Server:
   - Адрес: 158.160.127.151
   - Port: 10050

4. Открывает port 10050 в firewall
5. Добавляет custom метрики:
   - Nginx connections (количество соединений)
   - Disk usage (использование диска)
   - Memory usage (использование памяти)
   - Process count (количество процессов)

6. Запускает Agent и включает автозагрузку

**Результат:**
- ✓ Zabbix Agent установлен
- ✓ Подключен к Zabbix Server
- ✓ Отправляет метрики каждые 60 секунд
- ✓ Port 10050 открыт

---

## 📚 Role: elasticsearch

**Назначение:** Установка системы логирования (Elasticsearch + Kibana)

**Применяется к:** elasticsearch и kibana хосты

**На Elasticsearch сервере:**

1. Устанавливает Java (OpenJDK 11)
2. Добавляет репозиторий Elastic
3. Устанавливает Elasticsearch
4. Конфигурирует single-node кластер
5. Настраивает JVM heap size
6. Создает index templates для логов
7. Открывает ports:
   - 9200 (API)
   - 9300 (node communication)

8. Запускает Elasticsearch

**На Kibana сервере:**

1. Устанавливает Kibana
2. Конфигурирует подключение к Elasticsearch
3. Открывает port 5601 для веб-интерфейса
4. Запускает Kibana

**Результат:**
- ✓ Elasticsearch собирает логи
- ✓ Kibana визуализирует логи
- ✓ Веб-интерфейс на http://kibana_ip:5601

---

## 🚀 Использование ролей

### Применить все роли

```bash
cd ansible/
ansible-playbook playbooks/site.yml -i inventory/hosts.yml
```

### Применить одну роль

```bash
ansible-playbook playbooks/site.yml --tags common -i inventory/hosts.yml
ansible-playbook playbooks/site.yml --tags nginx -i inventory/hosts.yml
ansible-playbook playbooks/site.yml --tags zabbix-agent -i inventory/hosts.yml
ansible-playbook playbooks/site.yml --tags elasticsearch -i inventory/hosts.yml
```

### Применить на группе хостов

```bash
# Только webservers
ansible-playbook playbooks/site.yml -l webservers -i inventory/hosts.yml

# Только elasticsearch сервера
ansible-playbook playbooks/site.yml -l elasticsearch_servers -i inventory/hosts.yml
```

### Dry-run (посмотреть что изменится)

```bash
ansible-playbook playbooks/site.yml -C -D -i inventory/hosts.yml
```

### С логами

```bash
ansible-playbook playbooks/site.yml -v -i inventory/hosts.yml
ansible-playbook playbooks/site.yml -vv -i inventory/hosts.yml
ansible-playbook playbooks/site.yml -vvv -i inventory/hosts.yml
```

---

## ✅ Проверка ролей

### Проверить статус сервисов

```bash
# Nginx
ssh -F ssh.config web-1
sudo systemctl status nginx
exit

# Zabbix Agent
ssh -F ssh.config web-1
sudo systemctl status zabbix-agent
exit

# Elasticsearch
ssh -F ssh.config elasticsearch
sudo systemctl status elasticsearch
curl localhost:9200
exit
```

### Проверить логи

```bash
cat ansible.log | grep "nginx"
cat ansible.log | grep "zabbix"
cat ansible.log | grep "elasticsearch"
```

---

## 💡 Важные свойства ролей

### Идемпотентность

Все роли идемпотентны - повторное выполнение не вызывает проблем:

```bash
ansible-playbook playbooks/site.yml -i inventory/hosts.yml
ansible-playbook playbooks/site.yml -i inventory/hosts.yml  # Второй раз
ansible-playbook playbooks/site.yml -i inventory/hosts.yml  # Третий раз
```

### Модульность

Можно применять отдельные роли:

```bash
# Обновить только Nginx конфигурацию
ansible-playbook playbooks/site.yml --tags nginx -i inventory/hosts.yml

# Обновить мониторинг
ansible-playbook playbooks/site.yml --tags zabbix-agent -i inventory/hosts.yml
```

### Переиспользование

Роли можно использовать в других проектах:
- Скопировать папку roles/common в другой проект
- Использовать как базу для новых ролей

---

## 📚 Связанная документация

- quick-start.md - Быстрый старт
- server-provisioning.md - Архитектура
- implementation-guide.md - Полное руководство

---

**Все Ansible роли готовы к использованию!** ✅

**Автор:** Николай Зарубов
