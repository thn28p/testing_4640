#Create a new VPC
resource "digitalocean_vpc" "web_vpc" {
 name     = "vpcassign01"
 region   = var.region
}
