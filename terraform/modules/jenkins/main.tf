resource "aws_vpc" "jenkins-vpc" {
    cidr_block = "10.0.0.0/16"
    
    tags = {
        Name = "jenkins-vpc"
    }
}

resource "aws_subnet" "jenkins-subnet" {
    vpc_id = aws_vpc.jenkins-vpc.id
    cidr_block = "10.0.10.0/24"
    availability_zone = var.jenkins_availability_zone

    tags = {
        Name = "jenkins-subnet"
    }
}

resource "aws_internet_gateway" "jenkins-igw" {
    vpc_id = aws_vpc.jenkins-vpc.id

    tags = {
        Name = "jenkins-igw"
    }
}

resource "aws_route_table" "jenkins-route-table" {
    vpc_id = aws_vpc.jenkins-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.jenkins-igw.id
    }

    tags = {
        Name = "jenkins-route-table"
    }
}

resource "aws_route_table_association" "jenkins-rta" {
    subnet_id = aws_subnet.jenkins-subnet.id
    route_table_id = aws_route_table.jenkins-route-table.id
}

resource "aws_security_group" "jenkins-sg" {
    name = "jenkins-sg"
    vpc_id = aws_vpc.jenkins-vpc.id

    ingress{
        from_port = 22
        to_port = 22
        protocol = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "TCP"
        cidr_blocks = ["0.0.0.0/0"]   
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []
    }
    
    tags = {
        Name = "jenkins-sg"
    }
}

# to get dynamically ami image that we can use for ec2 creation
data "aws_ami" "amazon-linux-image"{
    most_recent = true

    owners = ["amazon"]

    filter {
        name = "name"
        values = ["al2023-ami-*-kernel-6.1-x86_64"]
    }

    filter{
        name = "virtualization-type"
        values = ["hvm"]
    }
}

resource "aws_key_pair" "ssh-key" {
    key_name = "jenkins-key-pair"
    public_key = file(var.jenkins_ssh_key)
}

resource "aws_instance" "jenkins-server" {
    ami = data.aws_ami.amazon-linux-image.id
    instance_type = var.jenkins_instance_type
    subnet_id = aws_subnet.jenkins-subnet.id
    vpc_security_group_ids = [aws_security_group.jenkins-sg.id]
    availability_zone = var.jenkins_availability_zone
    associate_public_ip_address = true
    key_name = "jenkins-key-pair"

    tags = {
        Name = "jenkins-server"
    }
}