variable public_key_path {
  description = "Path to the public key used for ssh access"
}
variable private_key {
  description = "private key"
}
variable app_disk_image {
  description = "Disk image for reddit app"
  default = "reddit-app-base"
}
variable subnet_id {
description = "Subnets for modules"
}
variable ip_host_db {
  description = "Database IP address"
}
