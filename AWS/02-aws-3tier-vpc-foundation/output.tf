output "vpc_id" {
  description = "ID of VPC"
  value       = aws_vpc.main

}

output "public_subnet_id" {
  value = aws_subnet.public[*].id

}

output "private_subnet_id" {
  value = aws_subnet.private[*].id

}

output "internet_gateway_id" {
  value = aws_internet_gateway.igw.id

}

output "public_route_table_id" {
  value = aws_route_table.public.id

}

output "nat_ip_id" {
  value = aws_eip.nat.id

}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "app_private_ip" {
  value = aws_instance.app_ec2_instance.private_ip

}

output "rds_endpoint" {
  value = aws_db_instance.mysql.endpoint
}


