output "vpc_id" {
  value       = aws_vpc.dev-vpc.id
  description = "defining output for VPC ID"
}

output "public_subnet_id" {
  value       = aws_subnet.public_subnet.id
  description = "Public subnet ID "
}

output "internet_gateway_id" {
  value = aws_internet_gateway.igw.id
}

output "website_url" {
  value = "http://${aws_instance.web_server.public_ip}"
}