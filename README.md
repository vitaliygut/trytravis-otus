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
