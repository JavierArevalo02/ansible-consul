terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  access_key = ""
  secret_key = ""
}

# Create a VPC
resource "aws_vpc" "homework6" {
  cidr_block = "192.168.0.0/24"
  tags = {
    Name = "homework6Endava-vpc",
    homework: "endava"
  }
}
#Create Subnet
resource "aws_subnet" "homework6"{
  vpc_id = aws_vpc.homework6.id
  cidr_block = "192.168.0.0/28"
  tags = {
    Name = "homework6Endava-subnet",
    homework: "endava"
  }
}
#Create internet gateway
resource "aws_internet_gateway" "homework6" {
  vpc_id = aws_vpc.homework6.id
  tags = {
    Name = "homework6Endava-internetGateway",
    homework: "endava"
  }
}
#Create route table
resource "aws_route_table" "homework6" {
  vpc_id = aws_vpc.homework6.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.homework6.id
  }

  tags = {
    Name = "homework6Endava-routeTable",
    homework: "endava"
  }
}
#Association routable to subnet
resource "aws_route_table_association" "homework6" {
  subnet_id      = aws_subnet.homework6.id
  route_table_id = aws_route_table.homework6.id
}

#Create a security group
resource "aws_security_group" "homework6" {
  name        = "allow http and ssh"
  description = "Allow http and ssh inbound traffic"
  vpc_id      = aws_vpc.homework6.id
  tags = {
    Name = "homework6Endava-SG",
    homework: "endava"
  }
}
#Create rules to security group
resource "aws_security_group_rule" "homework6" {
  for_each          = local.nsgrules 
  type              = each.value.type
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  security_group_id = aws_security_group.homework6.id
}
#Create network interface to Virtual machine
resource "aws_network_interface" "homework6" {
  subnet_id   = aws_subnet.homework6.id
  private_ips = ["192.168.0.10"]

  tags = {
    Name = "homework6Endava-netInterface",
    homework: "endava"
  }
}
#Create key to acces to the machine
resource "tls_private_key" "homework6" {
  algorithm = "RSA"
}

resource "local_file" "homework6" {
  content  = tls_private_key.homework6.private_key_pem
  filename = "mykey.pem"
}

resource "aws_key_pair" "homework6" {
  key_name   = "homework6Key"
  public_key = tls_private_key.homework6.public_key_openssh
}
#Create virtual machine ansible
resource "aws_instance" "homework6Ansible" {
  ami           = "ami-08c40ec9ead489470"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.homework6.key_name

  network_interface {
    network_interface_id = aws_network_interface.homework6.id
    device_index         = 0
  }
  tags = {
    Name = "homework6Endava-EC2-ansible",
    homework: "endava"
  }
  user_data = filebase64(var.commands)
}
#Associate elastic ip to instance
resource "aws_eip" "lb" {
  instance = aws_instance.homework6Ansible.id
  vpc      = true
}
#Create association from security group to resources
resource "aws_network_interface_sg_attachment" "homework6" {
  security_group_id    = aws_security_group.homework6.id
  network_interface_id = aws_instance.homework6Ansible.primary_network_interface_id
}

#create network interface to consulserver
resource "aws_network_interface" "homework6Consulserver" {
  subnet_id   = aws_subnet.homework6.id
  private_ips = ["192.168.0.11"]

  tags = {
    Name = "homework6Endava-netInterface",
    homework: "endava"
  }
}

#Create virtual machine consulserver 
resource "aws_instance" "homework6Consulserver" {
  ami           = "ami-08c40ec9ead489470"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.homework6.key_name

  network_interface {
    network_interface_id = aws_network_interface.homework6Consulserver.id
    device_index         = 0
  }
  tags = {
    Name = "homework6Endava-EC2-consulServer",
    homework: "endava"
  }
}

#create network interface to consulclient
resource "aws_network_interface" "homework6Consulclient" {
  subnet_id   = aws_subnet.homework6.id
  private_ips = ["192.168.0.12"]

  tags = {
    Name = "homework6Endava-netInterface",
    homework: "endava"
  }
}

#Create virtual machine consulclient
resource "aws_instance" "homework6ConsulClient" {
  ami           = "ami-08c40ec9ead489470"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.homework6.key_name

  network_interface {
    network_interface_id = aws_network_interface.homework6Consulclient.id
    device_index         = 0
  }
  tags = {
    Name = "homework6Endava-EC2-consulClient",
    homework: "endava"
  }
}

resource "aws_network_interface_sg_attachment" "homework6Consulclient" {
  security_group_id    = aws_security_group.homework6.id
  network_interface_id = aws_instance.homework6ConsulClient.primary_network_interface_id
}

resource "aws_network_interface_sg_attachment" "homework6ConsilServer" {
  security_group_id    = aws_security_group.homework6.id
  network_interface_id = aws_instance.homework6Consulserver.primary_network_interface_id
}

#Associate elastic ip to instance
resource "aws_eip" "lb2" {
  instance = aws_instance.homework6Consulserver.id
  vpc      = true
}

#Associate elastic ip to instance
resource "aws_eip" "lb3" {
  instance = aws_instance.homework6ConsulClient.id
  vpc      = true
}