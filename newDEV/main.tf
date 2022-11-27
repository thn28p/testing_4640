terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    } 
  }
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}

# data.tf
data "digitalocean_ssh_key" "ssh_key"{
  name = var.ssh_key
}

# network.tf
#add new project
data "digitalocean_project" "lab_project" {
name = var.project
}

#Create a new tag
resource "digitalocean_tag" "do_tag" {
name = var.tag
}


#Create a new VPC
resource "digitalocean_vpc" "web_vpc" {
 name     = var.vpc
 region   = var.region
}


# server.tf
#########################################################################
# Create a new Web Droplet in the var region
resource "digitalocean_droplet" "web" {
  image    = var.rocky
  size     = var.rsize
  count    = var.droplet_count
  name     = "web-${count.index + 1}"
  tags     = [digitalocean_tag.do_tag.id]
  region   = var.region
  ssh_keys = [data.digitalocean_ssh_key.ssh_key.id]
  vpc_uuid = digitalocean_vpc.web_vpc.id
  lifecycle {
   create_before_destroy = true
  }
}

resource "digitalocean_project_resources" "project_attach" {
  project = data.digitalocean_project.lab_project.id
  resources = flatten([ digitalocean_droplet.web.*.urn])
 }
#########################################################################

#add balancer
resource "digitalocean_loadbalancer" "public" {
 name = "loadbalancer-assign01"
 region = var.region

forwarding_rule {
   entry_port = 80
   entry_protocol = "http"

   target_port = 80
   target_protocol = "http"
 }

 healthcheck {
  port      = 22
  protocol  = "tcp"
 }

 droplet_tag = var.tag 
 vpc_uuid = digitalocean_vpc.web_vpc.id
}



resource "digitalocean_firewall" "web_dp_firewall" {

    # The name we give our firewall for ease of use                            #    
    name = "web-firewall"

    # The droplets to apply this firewall to                                   #
    droplet_ids = digitalocean_droplet.web.*.id

    # Internal VPC Rules. We have to let ourselves talk to each other
    inbound_rule {
        protocol = "tcp"
        port_range = "1-65535"
        source_addresses = [digitalocean_vpc.web_vpc.ip_range]
    }

    inbound_rule {
        protocol = "udp"
        port_range = "1-65535"
        source_addresses = [digitalocean_vpc.web_vpc.ip_range]
    }

    inbound_rule {
        protocol = "icmp"
        source_addresses = [digitalocean_vpc.web_vpc.ip_range]
    }

    outbound_rule {
        protocol = "udp"
        port_range = "1-65535"
        destination_addresses = [digitalocean_vpc.web_vpc.ip_range]
    }

    outbound_rule {
        protocol = "tcp"
        port_range = "1-65535"
        destination_addresses = [digitalocean_vpc.web_vpc.ip_range]
    }

    outbound_rule {
        protocol = "icmp"
        destination_addresses = [digitalocean_vpc.web_vpc.ip_range]
    }

    # Selective Outbound Traffic Rules

    # HTTP
    outbound_rule {
        protocol = "tcp"
        port_range = "80"
        destination_addresses = ["0.0.0.0/0", "::/0"]
    }

    # HTTPS
    outbound_rule {
        protocol = "tcp"
        port_range = "443"
        destination_addresses = ["0.0.0.0/0", "::/0"]
    }

    # ICMP (Ping)
    outbound_rule {
        protocol              = "icmp"
        destination_addresses = ["0.0.0.0/0", "::/0"]
    }
}

#####################################################################


#database.tf
#add database
resource "digitalocean_database_cluster" "cluster-mongo" {
  size       = "db-s-1vcpu-1gb"
  name       = "assign-mongo-cluster"
  engine     = "mongodb"
  version    = "4"
  #add 25 520
  tags   = [digitalocean_tag.do_tag.id]
  region     = var.region
  node_count = 1

  private_network_uuid = digitalocean_vpc.web_vpc.id
}

resource "digitalocean_database_firewall" "example-fw" {
  cluster_id = digitalocean_database_cluster.cluster-mongo.id

  rule {
    type  = "droplet"
    value = digitalocean_droplet.web[count.index].id
  }
}

# #create droplet that connects to db 
# resource "digitalocean_droplet" "web" {
#   image  = var.ubuntu
#   size   = var.usize 
#   count  = var.droplet_count
#   name   = "web-${count.index + 1}"
#   #add 25 520
#   tags   = [digitalocean_tag.do_tag.id]
#   region = var.region
# }


################################################################################

# Create a bastion server
resource "digitalocean_droplet" "bastion_dp" {
  image    = var.rocky
  size     = var.rsize
  name     = "bastion-${var.region}"
  tags   = [digitalocean_tag.do_tag.id]
  region   = var.region
  ssh_keys = [data.digitalocean_ssh_key.ssh_key.id]
  vpc_uuid = digitalocean_vpc.web_vpc.id
}

# firewall for bastion server
resource "digitalocean_firewall" "bastion_firewall" {
  
  #firewall name
  name = "ssh-bastion-firewall"

  # Droplets to apply the firewall to
  droplet_ids = [digitalocean_droplet.bastion_dp.id]

  inbound_rule {
    protocol = "tcp"
    port_range = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol = "tcp"
    port_range = "22"
    destination_addresses = [digitalocean_vpc.web_vpc.ip_range]
  }

  outbound_rule {
    protocol = "icmp"
    destination_addresses = [digitalocean_vpc.web_vpc.ip_range]
  }
}









output "server_ip" {
  description = "server ip address:"  
  value = digitalocean_droplet.web.*.ipv4_address
 }

# output "vpc_id" {  
#   description = "ID of project VPC:"  
#   value     = digitalocean_vpc.web_vpc.id
#   }

# output "lb_url" {
#     description = "URL of load balancer:"
#     value     = "loadbalancer-assign01"
#   }
      
# output "web_server_count" {
#     description = "Number of web servers provisioned"
#     value       = ${count.index}#var.droplet_count
#   }