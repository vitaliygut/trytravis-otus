output "external_ip_address_app" {
  value = module.app.external_ip_address_app
}
output "external_ip_address_db" {
  value = module.db.external_ip_address_db
}
output "internal_ip_address_db" {
  value = module.db.internal_ip_address_db
}

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
