provider "aws" {
  region = "us-east-1"
  access_key = "AKIA5EGEASLLKXNXPT5W"
  secret_key = "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"
}


# resource "aws_instance" "First_server" {
#     ami = "ami-042e8287309f5df03"
#     instance_type = "t2.micro"
#     tags = {
#       "Name" = "First_Instance"
#     }
# }

resource "aws_vpc" "first_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "Name" = "custom_vpc"
  }
}

resource "aws_subnet" "subnet-1" {
    vpc_id = aws_vpc.first_vpc.id
    cidr_block = "10.0.1.0/24"

    tags = {
      "Name" = "custom-subnet"
    }
}



