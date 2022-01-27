provider "aws" {
  region = "us-east-1"
  access_key = "AKIA5EGEASLLKXNXPT5W"
  secret_key = "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"
}

# Create VPC
resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "Name" = "production"
  }
}

# Create Subnet
resource "aws_subnet" "subnet-1" {
    vpc_id = aws_vpc.prod-vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"  

    tags = {
      "Name" = "prod-subnet"
    }
}


# Create IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.prod-vpc.id

  tags = {
    "Name" = "Prod-IGW"
  }
}

# Create Custom RT
resource "aws_route_table" "prod-route-table" {
    vpc_id = aws_vpc.prod-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    route {
        ipv6_cidr_block = "::/0"
        gateway_id = aws_internet_gateway.igw.id
    }
    tags = {
      "Name" = "Prod"
    }
  
}


# Associate Subnet With RT
resource "aws_route_table_association" "a" {
    subnet_id = aws_subnet.subnet-1.id
    route_table_id = aws_route_table.prod-route-table.id  
}


# Create SG To Allow Port 80,22,443
resource "aws_security_group" "allow_web" {
    name = "allow_web_traffic"
    description = "Allow WEB Inbound Traffic"
    vpc_id = aws_vpc.prod-vpc.id 

    ingress {
        description = "HTTPS"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "HTTP"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      "Name" = "allow_web"
    }
  
}

# Create Network Interface With IP In The Subnet That Was Created In Step-4
resource "aws_network_interface" "web-server-nic" {
    subnet_id = aws_subnet.subnet-1.id
    private_ip = "10.0.1.50"
    security_groups = [aws_security_group.allow_web.id]

    tags = {
      "Name" = "prod"
    }
}



# # Assign EIP To The Network Interface Created In Step-7
# resource "aws_eip" "eip" {
#     vpc = true
#     network_interface = aws_network_interface.web-server-nic.id
#     associate_with_private_ip = "10.0.1.50"
#     # depends_on = ["aws_internet_gateway.igw"] 
#     # depends_on = ["aws_instance.aws-server-instance.id"]      
# }


# Create Ubuntu Server And Install/Enable Apache2
resource "aws_instance" "aws-server-instance" {
  ami = "ami-042e8287309f5df03"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "docker-test"

  network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.web-server-nic.id
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo your very first server > /var/www/html/index.html'
              EOF
  tags = {
    "Name" = "web-server"
  }
}
