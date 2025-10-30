resource "local_file" "ansible_inventory" {
  content = "# Ansible inventory"
  filename = "${path.module}/../ansible/inventory/hosts.yml"
}
