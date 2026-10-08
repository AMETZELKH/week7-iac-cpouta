output "web_ip" {
  description = "Public floating IP address of the web server"
  value       = openstack_networking_floatingip_v2.web.address
}

output "web_url" {
  description = "URL of the web server"
  value       = "http://${openstack_networking_floatingip_v2.web.address}"
}

output "ssh_command" {
  description = "SSH command for checking the VM"
  value       = "ssh -i ~/.ssh/week7_ed25519 ubuntu@${openstack_networking_floatingip_v2.web.address}"
}