output "public_ip" {
  value       = aws_instance.ssh-example.public_ip
  description = "The public IP address of the web server"
}