# 🚀 Быстрый старт: Развертывание инфраструктуры Terraform + Ansible

## 📋 Что нужно сделать перед началом

### Установить необходимые инструменты

Перед развертыванием инфраструктуры нужно установить:

**Terraform** - для создания облачной инфраструктуры:
```bash
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform --version
```

**Ansible** - для конфигурирования серверов:
```bash
sudo apt-add-repository ppa:ansible/ansible -y
sudo apt update
sudo apt install ansible -y
ansible --version
```

**Yandex Cloud CLI** - для управления облаком:
```bash
curl https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
yc --version
```

## 🔑 Подготовка учетных данных

### Шаг 1: Создаем SSH ключи для доступа к серверам

Если ключь есть в `~/.ssh/id_rsa`, этот шаг можно пропустить.

Иначе генерируем новые ключи:
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
```

Проверяем что ключи созданы:
```bash
ls -la ~/.ssh/
cat ~/.ssh/id_rsa.pub
```

### Шаг 2: Получаем токен для Yandex Cloud API

Авторизуемся в Yandex Cloud:
```bash
yc auth login
```

Создаем service account для Terraform:
```bash
yc iam service-account create --name terraform-sa
```

Даем ему права администратора:
```bash
yc iam service-account add-access-binding terraform-sa \
  --role roles/editor
```

Генерируем IAM токен (сохраняем его, он нужен для terraform.tfvars):
```bash
yc iam create-token --service-account-name terraform-sa
```

### Шаг 3: Узнаем ID облака и каталога

```bash
yc config list
```

Вывод будет примерно такой:
```
cloud-id: b1g1234567890abc
folder-id: b1g0987654321xyz
```

Эти значения нужны для terraform.tfvars.

## 📁 Настройка Terraform переменных

Переходим в директорию terraform:
```bash
cd ~/sys-diplom-terraform/terraform/
```

Создаем файл `terraform.tfvars` с учетными данными:
```bash
cat > terraform.tfvars << 'EOF'
# Учетные данные Yandex Cloud
yc_token      = "t1.9euelZrO8Z..."          # Ваш token из шага выше
yc_cloud_id   = "b1g1234567890abc"         # Из yc config list
yc_folder_id  = "b1g0987654321xyz"         # Из yc config list
yc_zone       = "ru-central1-a"

# SSH ключи для доступа
public_key_path  = "~/.ssh/id_rsa.pub"
private_key_path = "~/.ssh/id_rsa"

# Конфигурация виртуальных машин
web_servers_count = 2           # Количество веб-серверов
vm_cores          = 2           # Количество ядер процессора
vm_memory         = 4           # Объем оперативной памяти (GB)
core_fraction     = 20          # 20% использование ядер (для экономии)
preemptible       = true        # Прерываемые ВМ дешевле на 50-70%
EOF
```

## ⚙️ Развертывание инфраструктуры

### Шаг 1: Инициализация Terraform

Terraform загружает необходимые провайдеры и модули:
```bash
terraform init
```

### Шаг 2: Планирование развертывания

Смотрим какие ресурсы будут созданы:
```bash
terraform plan
```

Проверяем что будет создано:
- ✓ VPC Network и подсети
- ✓ Security Groups
- ✓ 6 виртуальных машин
- ✓ Application Load Balancer
- ✓ Snapshot Schedule для резервных копий

### Шаг 3: Развертывание

Создаем всю инфраструктуру:
```bash
terraform apply -auto-approve
```

**Ожидаем 5-10 минут пока:**
1. Создаются виртуальные машины в Yandex Cloud
2. Генерируется Ansible inventory файл с IP адресами
3. Автоматически запускается Ansible playbook
4. Устанавливаются все необходимые сервисы (Nginx, Zabbix, Elasticsearch, Kibana)

## ✅ Проверка что всё работает

### 1. Смотрим IP адреса всех созданных серверов

```bash
terraform output
```

Результат:
```
bastion_public_ip = "158.160.55.35"
web_1_private_ip = "192.168.20.21"
web_2_private_ip = "192.168.30.27"
zabbix_public_ip = "158.160.127.151"
kibana_public_ip = "158.160.124.158"
elasticsearch_private_ip = "192.168.20.9"
```

### 2. Проверяем доступность всех серверов

Переходим в папку Ansible:
```bash
cd ../ansible
```

Проверяем что все серверы доступны:
```bash
ansible all -i inventory/hosts.yml -m ping
```

Все должны ответить SUCCESS:
```
bastion | SUCCESS => { "ping": "pong" }
web-1 | SUCCESS => { "ping": "pong" }
web-2 | SUCCESS => { "ping": "pong" }
zabbix-server | SUCCESS => { "ping": "pong" }
```

### 3. Подключаемся к серверам через SSH

Заходим на веб-сервер web-1 (через Bastion Host):
```bash
ssh -F ssh.config web-1
```

Проверяем что Nginx работает:
```bash
curl http://localhost
sudo systemctl status nginx
```

Выходим:
```bash
exit
```

### 4. Открываем веб-интерфейсы в браузере

**Zabbix (мониторинг):**
```
URL: http://<zabbix_public_ip>
Логин: admin
Пароль: zabbix
```

**Kibana (логирование):**
```
URL: http://<kibana_public_ip>:5601
```

**Веб-сайт (через Load Balancer):**
```
URL: http://<alb_ip>
```

## 📊 Доступ к основным сервисам

| Сервис | Адрес | Авторизация |
|--------|-------|-------------|
| Zabbix (Мониторинг) | http://<zabbix_ip> | admin / zabbix |
| Kibana (Логирование) | http://<kibana_ip>:5601 | Без авторизации |
| Веб-сайт | http://<alb_ip> | Без авторизации |
| Elasticsearch API | http://<elasticsearch_ip>:9200 | Без авторизации |

## 🔍 что-то пошло не так   

**Ошибка: "terraform init failed"**
```bash
rm -rf .terraform .terraform.lock.hcl
terraform init
```

**Ошибка: "Permission denied (publickey)"**
```bash
chmod 600 ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub
```

**Ошибка: "Timeout connecting to host"**
```bash
sed -i 's/timeout = 30/timeout = 60/' ../ansible/ansible.cfg
cd ../terraform
ansible-playbook playbooks/site.yml -i inventory/hosts.yml -v
```

**Удаляем всю инфраструктуру и начинаем заново**
```bash
cd terraform/
terraform destroy -auto-approve
```

## 📚 Полезные команды для управления

Смотрим список всех виртуальных машин:
```bash
yc compute instance list
```

Смотрим логи Ansible:
```bash
cat ../ansible/ansible.log
```

Пересоздаем одну виртуальную машину:
```bash
terraform taint yandex_compute_instance.web_1
terraform apply -auto-approve
```

Копируем файл на сервер:
```bash
scp -F ssh.config myfile.txt web-1:/tmp/
```

Выполняем команду на всех серверах одновременно:
```bash
ansible all -i ../ansible/inventory/hosts.yml -m shell -a "uptime"
```

## ⏱️ Итоговая информация

- **Время развертывания:** 5-10 минут
- **Стоимость:** ~$5-10/день (благодаря использованию прерываемых ВМ и 20% использованию ядер)
- **Автор:** Николай Зарубов
- **Email:** nvzarubov@gmail.com
