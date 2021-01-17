# vitaliygut_infra
vitaliygut Infra repository

HW3
=========================================
bastion_IP = 178.154.227.202
someinternalhost_IP = 10.130.0.14

Cпособ подключения к someinternalhost в одну команду

ssh -t -i ~/.ssh/key -A appuser@public_ip_bastion 'ssh ip_someinternalhost'


Подключение из консоли при помощи команды вида ssh someinternalhost:


Host *
ForwardAgent yes

	Host bastion
	IdentityFile ~/.ssh/key
	HostName ip_bastion
	User appuser

        Host someinternalhost
        IdentityFile ~/.ssh/key
        HostName ip_someinternalhost
        User appuser
	ProxyJump bastion

После запуска vpn сервера в логах были ошибки связанные с неудачной попыткой добыить правила в iptables, дополнително установил iptable и рестрарт службы pritunl

SSL
В настройках сервера указал домен  pritunl.178.154.227.202.sslip.io

HW4
=========================================

testapp_IP = 130.193.37.11
testapp_port = 9292

Используйте созданные ранее скрипты для
создания startup script, который будет запускаться при создании инстанса:

yc compute instance create \
--name reddit-app2 \
--hostname reddit-app2 \
--memory=4 \
--create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB \
--network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
--metadata-from-file user-data=metadata.yaml \
--metadata serial-port-enable=1

HW6
=========================================
Основное задание:
1. Использование input vars, описываем переменные в variables.tf
```
...
variable cloud_id {
  description = "Cloud"
}
variable folder_id {
  description = "Folder"
}
variable zone {
  description = "Zone"
  default     = "ru-central1-a"
  ...
  ```
2. Определяем переменные в terraform.tfvars
```
cloud_id                 = "qaz123"
folder_id                = "qaz456"
image_id                 = "qaz789"
```
3. Указываем переменные в main.tf
```
folder_id                =  var.folder_id
```

Дополнительное задание:

1. Создаем файл lb.tf и определяем целевую группу
```
resource "yandex_lb_target_group" "app" {
  name      = "target-group-reddit-app"
  region_id = var.region_id

  target {
    subnet_id = var.subnet_id
    address   = "${yandex_compute_instance.app.network_interface.0.ip_address}"
  }
```

2. Настройка балансировщика с указанием цлевой группы
```
...
resource "yandex_lb_network_load_balancer" "lb" {
  name = "reddit-load-balancer"

  listener {
    name = "http-listener"
    port = 9292
    external_address_spec {
      ip_version = "ipv4"
    }
  }

 attached_target_group {
    target_group_id = "${yandex_lb_target_group.app.id"
	healthcheck {
      name = "http"
      http_options {
        port = 9292
        path = "/"
...
```
3. Добавление вывода в output для балнсировщика
```
output "external_lb_ip_address_app" {
  value = yandex_lb_network_load_balancer.lb.listener.*.external_address_spec[0].*.address
}
```
4. Добавление в балансировщик второй созданный сервер
```
  target {
    subnet_id = var.subnet_id
    address   = "${yandex_compute_instance.app.0.network_interface.0.ip_address}"
  }
```
5. Добавление вывода в output для второго сервера
```
output "external_ip_address_app" {
  value = yandex_compute_instance.app.0.network_interface.0.nat_ip_address
}
output "internal_ip_address_app" {
  value = yandex_compute_instance.app.0.network_interface.0.ip_address
```
6. Удаляем инстанс и добавляем новый параметр ресурса  count
```
variable count_app {
  description = "count instances"
  default     = 1
```

HW7
=============================================

1. Создадим сеть с помощью yandex_vpc_network и yandex_vpc_subnet,  добавляем в main.tf следующие строки:

```
resource "yandex_vpc_network" "app-network" {
  name = "reddit-app-network"
}

resource "yandex_vpc_subnet" "app-subnet" {
  name           = "reddit-app-subnet"
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.app-network.id}"
  v4_cidr_blocks = ["192.168.10.0/24"]
}
```
2. Делаем ссылку на на атрибут ресурса в наших VM
```
 network_interface {
    subnet_id = yandex_vpc_subnet.app-subnet.id
    nat = true
  }
```
3. Создаем 2 новых шаблона для packer app.json и db.json и редактируем параметры
```
....
 "image_name": "reddit-app-base-{{timestamp}}"
 "image_family": "reddit-app-base"
....
```
4. Запускаем билд образов

5. Разбиваем конфиг main.tf на несколько конфигов, cоздаем файл app.tf db.tf и добавляем новые переменные
```
variable app_disk_image {
  description = "disk image for reddit app"
  default     = "reddit-app-base"
}
variable db_disk_image {
  description = "disk image for mongodb"
  default     = "reddit-db-base"
```
оставляем в main.tf только
```
provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}
```
вносим изменения outputs.tf
```
output "external_ip_address_app" {
  value = yandex_compute_instance.app.network_interface.0.nat_ip_address
}
output "external_ip_address_db" {
  value = yandex_compute_instance.db.network_interface.0.nat_ip_address
}
```
6. Проверяем работу
```
terraform plan; terraform apply --auto-approve
```
7. Переход к работе с модульной структурой. Создаем папку modules внутри terraform и в каждом из модулей app и db создаем  main.tf, outputs.ft и variables.tf

outputs.tf
```
output "external_ip_address_app" {
  value = yandex_compute_instance.app.network_interface.0.nat_ip_address
}
```
variables.tf
```
variable public_key_path {
  description = "Path to the public key used for ssh access"
}
  variable db_disk_image {
  description = "Disk image for reddit db"
  default = "reddit-db-base"
}
variable subnet_id {
description = "Subnets for modules"
}
```
app/main.tf
```
resource "yandex_compute_instance" "app" {
  name = "reddit-app"

  labels = {
    tags = "reddit-app"
  }
  resources {
    core_fraction = 5
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.app_disk_image
    }
  }
  ....
```
8. удаляем из файлы app.tf, db.tf и vpc.tf

9. В файл main.tf вставляем секции вызова созданных нами модулей
```
provider "yandex" {
service_account_key_file = var.service_account_key_file
cloud_id = var.cloud_id
folder_id = var.folder_id
zone = var.zone
}
module "app" {
source = "./modules/app"
public_key_path = var.public_key_path
app_disk_image = var.app_disk_image
subnet_id = var.subnet_id
}
module "db" {
source = "./modules/db"
public_key_path = var.public_key_path
db_disk_image = var.db_disk_image
subnet_id = var.subnet_id
}
```
изменяем outputs.tf
```
output "external_ip_address_app" {
  value = module.app.external_ip_address_app
}
output "external_ip_address_db" {
  value = module.db.external_ip_address_db
}
```
загружаем модули
```
terraform get
```
проверяем работу
```
terraform plan; terraform apply --auto-approve
```
10. Переиспользование модулей. Создаем среды prod и stage

копируем в эти каталоги наши основные рабочией файлы
```
main.tf  outputs.tf variables.tf terraform.tfvars
```
11. Форматируем файлы
```
terraform fmt
```
12. Проверяем работу
```
terraform init; terraform apply --auto-approve
```
Задание с ⭐

1. Использование внешнего backend. Яндекс использует хранилища формата S3. Создаем бакет и получаем необходимые access_key и secret_key

в папке terraform создадим файл backet.tf
```
provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

resource "yandex_storage_bucket" "tf-bucket" {
  bucket        = var.bucket_name
}
```
создаем bucket
```
terraform apply --auto-approve
```
2. Создаем в каждой из сред файл backend.tf для указания бекэнда
```
terraform {
  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "infra-tf"
    region     = "ru-central1"
    key        = "stage/terraform.tfstate"
    access_key = "123"
    secret_key = "123"

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}
```
3. Проверка работы, переходим в директорию stage или prod
```
terraform init; terraform apply --auto-approve
```
Задание с ⭐⭐

1. Добавим необходимые provisioner в модули для деплоя и работы приложения.

Создаем файл конфига puma.service для нашего приложения с указанием адрес для подключения к базе
```
[Unit]
Description=Puma HTTP Server
After=network.target

[Service]
Type=simple
User=ubuntu
Environment="DATABASE_URL=${ip_host_db}"
WorkingDirectory=/home/ubuntu/reddit
ExecStart=/bin/bash -lc 'puma'
Restart=always

[Install]
WantedBy=multi-user.target
```

2. Теперь в main.tf добавив провижионеры.
```
  connection {
    type        = "ssh"
    host        = self.network_interface.0.nat_ip_address
    user        = "ubuntu"
    agent       = false
    private_key = file(var.private_key)
  }
 provisioner "file" {
    content     = templatefile("${path.module}/files/puma.service", { ip_host_db = var.ip_host_db })
    destination = "/tmp/puma.service"
  }

 provisioner "remote-exec" {
    script = "${path.module}/files/deploy.sh"
  }
  ```

3. Мы используем переменную var.ip_host_db ее также нужно определить в файле variables.tf
```
  variable ip_host_db {
  description = "Database IP address"
}
```
4. Чтобы получить значение переменной мы добавляем в main.tf
```
module "app" {
  source          = "../modules/app"
  public_key_path = var.public_key_path
  app_disk_image  = var.app_disk_image
  subnet_id       = var.subnet_id
  ip_host_db      = module.db.internal_ip_address_db
  private_key     = var.private_key
}
```
и получаем прописываем вывод значения в db/outputs.tf
```
output "internal_ip_address_db" {
  value = yandex_compute_instance.db.network_interface.0.ip_address
}
```

5. Создаем в db/files/ mongod.conf для прослушивания порта на нужном интерфейсе
```
...
# network interfaces
net:
  bindIp: ${ip_host_db}
  port: 27017
...
```

6. Указав интерфейс для работы, теперь создадим скрипт который будет подкидывать наш конфиг deploy.sh на хост
```
#!/bin/bash
sudo mv -f /tmp/mongod.conf /etc/mongod.conf
sudo systemctl restart mongod
```

7. Осталось добавить провижионеры в наш файл в db main.tf для модуля DB
```
  connection {
    type        = "ssh"
    host        = self.network_interface.0.nat_ip_address
    user        = "ubuntu"
    agent       = false
    private_key = file(var.private_key)
  }
  provisioner "file" {
    content     = templatefile("${path.module}/files/mongod.conf", { ip_host_db = yandex_compute_instance.db.network_interface.0.ip_address})
    destination = "/tmp/mongod.conf"
  }
  provisioner "remote-exec" {
    script = "${path.module}/files/deploy.sh"
  }
  ```

8. Проверяем работу
```
terraform destroy --auto-approve; terraform apply --auto-aprove
```

HW8
===========================

1. Устанавлием Ansible
brew install ansible
2. Создаем каталог ansible и файл inventory, проверяем ...

```ansible appserver -i ./inventory -m ping```
```
...
appserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
```
3. Создаем файл inventory.yml

```
---
app:
  hosts:
    appserver:
      ansible_host:
        84.201.131.179
db:
  hosts:
    dbserver:
      ansible_host:
        84.201.128.39
```

4. Дабавляем clone.yml

```
---
- name: Clone
  hosts: app
  tasks:
    - name: Clone repo
      git:
        repo: https://github.com/express42/reddit.git
        dest: /home/ubuntu/reddit
```

5. После запуска плейбука на сервере нет измененного состояния, так при создании окружения тераформом мы уже скачали этот репозиторий
```appserver                  : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0```
6. Выполняем команду ```ansible app -m command -a 'rm -rf ~/reddit'``` - папка с приложением удалена, повторный запуск плейбука clone.yml приведет к загрузки приложения из репозитария.

HW9
===========================
Задание с ⭐

1. Дабвил outputs.tf
```
### The Ansible inventory file
resource "local_file" "AnsibleInventory" {
 content = templatefile("inventory.tmpl",
 {
  app-ext-ip = module.app.external_ip_address_app,
  db-ext-ip = module.db.external_ip_address_db,
  db-int-ip = module.db.internal_ip_address_db
 }
 )
 filename = "../../ansible/inventory.ini"
}
```
и шаблон для формирования файла inventory.tmpl
```
[db]
dbserver ansible_host=${db-ext-ip}
[app]
appserver ansible_host=${app-ext-ip} db_host=${db-int-ip}
```
2.  Переменную db_host берем из inventory файла
```
vars:
   db_host: "{{db_host}}"
```
