
output "public_ip" {
 value       = aws_instance.web.public_ip
 description = "Public IP Address of EC2 instance"
}

output "instance_id" {
 value       = aws_instance.web.id
 description = "Instance ID"
}
