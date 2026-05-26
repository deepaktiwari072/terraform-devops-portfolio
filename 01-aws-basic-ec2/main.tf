# defining data block here for finding AMI ID for ec2 instance

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}




# Defining VPC resource information below
resource "aws_vpc" "dev-vpc" {
  #Taking cidr value from variable 
  cidr_block = var.vpc_cidr
  tags = {
    "name"       = "Development-vpc"
    "managed-by" = "Terraform"
  }

}

resource "aws_subnet" "public_subnet" {
  #This means: create subnet inside the VPC you already created.
  vpc_id                  = aws_vpc.dev-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true
  tags = {
    "name" = var.aws_subnet_tag
  }

}
# Internet gateway allow VPC to reach to internet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.dev-vpc.id
  tags = {
    "name" = "dev-igw"
  }

}

resource "aws_route_table" "app_route" {
  vpc_id = aws_vpc.dev-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id # referring IGW inside the VPC you already created
  }
}
# This connects your public subnet to the public route table.
resource "aws_route_table_association" "public" {
  route_table_id = aws_route_table.app_route.id # referring route table which above created 
  subnet_id      = aws_subnet.public_subnet.id  # referring subnet which already created above 

}

resource "aws_security_group" "web_sg" {
  name        = "web_server_sg"
  description = "allow ssh and http traffic"
  vpc_id      = aws_vpc.dev-vpc.id

  ingress {
    description = "allow ssh traffic from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["152.58.129.143/32"] # replace this with your actual IP
  }

  ingress {
    description = "Allow http traffic from everywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all as outbound traffic "
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }

  tags = {
    "Name" = "web-server-sg"
  }

}

resource "aws_instance" "web_server" {
  ami                         = "ami-00563078bca04e287"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
  key_name = "dev-web-server-key"
  availability_zone           = var.az
  user_data                   = <<-EOF
  #!/bin/bash
  dnf update -y
  dnf install -y nginx
  systemctl enable nginx
  systemctl start nginx

  cat > /usr/share/nginx/html/index.html <<HTML
  <html>
    <head>
      <title>Terraform Web Server</title>
    </head>
    <body>
      <h1>Hello from Terraform</h1>
      <p>This EC2 instance was created using Terraform on AWS.</p>
    </body>
  </html>
  HTML
EOF
  tags = {
    "Name" = "terraform-web-server"
  }

}

