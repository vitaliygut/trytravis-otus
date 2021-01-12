variable db_disk_image {
  description = "Disk image for reddit db"
  default = "reddit-db-base"
}
variable public_key_path {
  description = "Path to the public key used for ssh access"
}
variable private_key {
  description = "private key"
}
variable subnet_id {
description = "Subnets for modules"
}
