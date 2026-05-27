resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    "Name" = "Prod-VPC"
  }

}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidr)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr[count.index]
  availability_zone       = var.availibility_zone[count.index]
  map_public_ip_on_launch = true

  tags = {
    "Name" = "Public_subnet-${count.index + 1}"
    tier   = "public"
  }

}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr[count.index]
  availability_zone = var.availibility_zone[count.index]

  tags = {
    "name" = "private_subnet-${count.index + 1}"
    tier   = "private"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    "name" = "igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    "Name" = "Public_route_table"
  }

}

resource "aws_route_table_association" "public" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public[count.index].id
  count          = length(aws_subnet.public)

}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    "name" = "nat-eip"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  subnet_id     = aws_subnet.public[0].id
  allocation_id = aws_eip.nat.id
  tags = {
    "name" = "main_nat_gateway"
  }

  depends_on = [aws_internet_gateway.igw]

}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id

  }

}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

########################################################
#From here we are going to deploy resources inside VPC as above we have created 3 tier infrastructure for deploying resources 

resource "aws_security_group" "bastion_sg" {
    name = "bastion_sg"
    description = "Allow ssh access to bastion host"
    vpc_id = aws_vpc.main.id

    ingress  {
      cidr_blocks = [ "152.58.131.174/32" ]
      from_port = 22
      to_port = 22
      protocol = "tcp"
    } 

    egress {
     description = "Allow all port as outbound"
     cidr_blocks = [ "0.0.0.0/0" ]
     from_port = 0
     to_port = 0
     protocol = "-1"
    } 

    tags = {
      "name" = "Bastion_host"
    }
    
}

resource "aws_security_group" "app_sg" {

    name = "app_sg"
    vpc_id = aws_vpc.main.id
    description = "Allow port 80 from bastion and public"
    ingress  {
      from_port = 22
      to_port = 22
      security_groups = [ aws_security_group.bastion_sg.id]
      protocol = "tcp"
      
    } 
    ingress {
      cidr_blocks = [ var.vpc_cidr ]
      from_port = 80
      to_port = 80
      protocol = "tcp"
      description = "Allow port 80 from VPC_CIDR"

    } 
    egress {
      cidr_blocks = [ "0.0.0.0/0" ]
      description = "Allow everything as outbound"
      from_port = 0
      to_port = 0
      protocol = "-1"
    } 
    tags = {
      "name" = "app-sg"
    }
    } 

    resource "aws_security_group" "db_sg" {
        name = "db_sg"
        description = "Security group for postgress DB"
        vpc_id = aws_vpc.main.id

        ingress  {
          security_groups = [ aws_security_group.app_sg.id ]
          description = "Allow port 3306 from app_sg"
          from_port = 3306
          to_port = 3306
          protocol = "tcp"
        } 

        egress  {
          cidr_blocks = [ "0.0.0.0/0" ]
          description = "Allow all as outbound "
          from_port = 0
          to_port = 0
          protocol = "-1"
        } 

        tags = {
          "name" = "db-sg"
        }
    }


###################################################
# From here I am creating resources like EC2, DB and bastion host
################################################################
resource "aws_instance" "bastion" {
    ami = data.aws_ami.amazon_linux_2023.id
    instance_type = "t3.micro"
    subnet_id = aws_subnet.public[0].id
    vpc_security_group_ids = [ aws_security_group.bastion_sg.id ]
    associate_public_ip_address = true
    key_name = var.key_name

    tags = {
      "name" = "bastion-ec2-host"
    }
   
}

resource "aws_instance" "app_ec2_instance" {
    ami = data.aws_ami.amazon_linux_2023.id
    instance_type = "t3.micro"
    subnet_id = aws_subnet.private[0].id
    vpc_security_group_ids = [ aws_security_group.app_sg.id ]
    key_name = var.key_name
    user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y nginx mariadb105
    systemctl enable nginx
    systemctl start nginx
  EOF

  tags = {
    Name = "private-app-server"
  }
    
}

resource "aws_db_subnet_group" "main_db" {
    subnet_ids = aws_subnet.private[*].id
    name = "three-tier-db-subnet-group"

    tags = {
      "name" = "three-tier-db-subnet-group"
    }
    
}

resource "aws_db_instance" "mysql" {
    instance_class = "db.t3.micro"
    allocated_storage = 20
    db_name = "appdb"
    db_subnet_group_name = aws_db_subnet_group.main_db.id
    vpc_security_group_ids = [ aws_security_group.db_sg.id]
    username = var.db_username
    password = var.db_password
    engine = "mysql"
    engine_version = "8.0"
    publicly_accessible = false
    skip_final_snapshot = true # in production env it will be set as true
    deletion_protection =  false # in Production env it will be set as true
    tags = {
      "name" = "mysql_db"
    }
    
}


  
    
