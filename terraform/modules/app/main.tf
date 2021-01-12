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

  network_interface {
    subnet_id = var.subnet_id
    nat = true
  }

  metadata = {
  ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
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

}
