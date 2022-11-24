#add database
resource "digitalocean_database_firewall" "example-fw" {
  cluster_id = digitalocean_database_cluster.mongodb-example.id

  rule {
    type  = "tag"
    value = "tag7assign01"
  }
}

resource "digitalocean_droplet" "tag7assign02" {
  count  = var.droplet_count
  name   = "web-${count.index + 1}"
  size   = "s-1vcpu-1gb"
  image  = "ubuntu-22-04-x64"
  region = var.region
}

resource "digitalocean_database_cluster" "mongodb-example" {
  name       = "example-mongo-cluster"
  engine     = "mongodb"
  version    = "4" 
  size       = "db-s-1vcpu-1gb"
  region     = var.region
  node_count = 1 

  private_network_uuid = digitalocean_vpc.web_vpc.id
}


