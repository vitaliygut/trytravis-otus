resource "yandex_lb_target_group" "app" {
  name      = "target-group-reddit-app"
  region_id = var.region_id

  target {
    subnet_id = var.subnet_id
    address   = "${yandex_compute_instance.app.0.network_interface.0.ip_address}"
  }
  target {
    subnet_id = var.subnet_id
    address   = "${yandex_compute_instance.app.1.network_interface.0.ip_address}"
  }

}

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
    target_group_id = "${yandex_lb_target_group.app.id}"

    healthcheck {
      name = "http"
      http_options {
        port = 9292
        path = "/"
      }
    }
  }
}
