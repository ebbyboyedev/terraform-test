terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}


# Create a VPC
resource "aws_vpc" "test_vpc" {
  cidr_block = "10.0.0.0/16"
}


resource "aws_subnet" "test_public_subnet" {
  vpc_id     = aws_vpc.test_vpc.id
  cidr_block = "${cidrsubnet(aws_vpc.test_vpc.cidr_block, 8, 1)}"

  tags = {
    Name = "test public subnet"
  }
}


resource "aws_subnet" "test_private_subnet" {
  vpc_id     = aws_vpc.test_vpc.id
  cidr_block = "${cidrsubnet(aws_vpc.test_vpc.cidr_block, 8, 2)}"

  tags = {
    Name = "test private subnet"
  }
}


resource "aws_subnet" "test_database_subnet" {
  vpc_id     = aws_vpc.test_vpc.id
  cidr_block = "${cidrsubnet(aws_vpc.test_vpc.cidr_block, 8, 3)}"

  tags = {
    Name = "test database subnet"
  }
}

resource "aws_internet_gateway" "test_igw" {
  vpc_id = aws_vpc.test_vpc.id

  tags = {
    Name = "test igw"
  }
}

resource "aws_route_table" "test_public_rt" {
  vpc_id = aws_vpc.test_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test_igw.id
  }

  tags = {
    Name = "test public rt"
  }
}


resource "aws_route_table" "test_private_rt" {
  vpc_id = aws_vpc.test_vpc.id

 

  tags = {
    Name = "test private rt"
  }
}


resource "aws_route_table" "test_database_rt" {
  vpc_id = aws_vpc.test_vpc.id



  tags = {
    Name = "test db rt"
  }
}

resource "aws_route_table_association" "test_public_association" {
  subnet_id      = aws_subnet.test_public_subnet.id
  route_table_id = aws_route_table.test_public_rt.id
}

resource "aws_route_table_association" "test_private_association" {
  subnet_id      = aws_subnet.test_private_subnet.id
  route_table_id = aws_route_table.test_private_rt.id
}

resource "aws_route_table_association" "test_database_association" {
  subnet_id      = aws_subnet.test_database_subnet.id
  route_table_id = aws_route_table.test_database_rt.id
}




resource "aws_nat_gateway" "test_nat_gateway" {
  subnet_id     = aws_subnet.test_public_subnet.id

  tags = {
    Name = "gw NAT"
  }
  depends_on = [aws_internet_gateway.test_igw]
}


resource "aws_default_security_group" "public_server" {
  vpc_id = aws_vpc.test_vpc.id

  ingress {
    protocol  = tcp
    self      = true
    from_port = 80
    to_port   = 80
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_default_security_group" "private_server" {
  vpc_id = aws_vpc.test_vpc.id

  ingress {
    protocol  = tcp
    self      = true
    from_port = 443
    to_port   = 443
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_default_security_group" "database_server" {
  vpc_id = aws_vpc.test_vpc.id

  ingress {
    protocol  = tcp
    self      = true
    from_port = 3306
    to_port   = 3306
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "test_frontend_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  tags = {
    Name = "frontend server"
  }
}

resource "aws_instance" "test_backend_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  tags = {
    Name = "backend server"
  }
}

resource "aws_db_subnet_group" "test_rds_subnet_group" {
  name       = "test_subnet"
  subnet_ids = [aws_subnet.test_private_subnet.id, aws_subnet.test_database_subnet.id]

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "test_db" {
  allocated_storage    = 10
  db_name              = "my_test_db"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "my_test_user"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
}
