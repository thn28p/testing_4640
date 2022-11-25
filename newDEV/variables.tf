
#terraform variables
#
# The API token
variable "do_token" {}

#set the default region to sfo3
variable "region" {
 type = string
default = "sfo3"
}

#set the default droplet count
variable "droplet_count" {
 type = number
 default = 2 
}

#set ssh key name
variable "ssh_key" {
 type = string
 default = "lab4Rocky"
}

#set project name
variable "project" {
 type = string
 default = "4640_labs"
}

#set tag name
variable "tag" {
 type = string
 default = "tag7assign01"
}

#set vpc name
variable "vpc" {
 type = string
 default = "vpcassign01"
}
