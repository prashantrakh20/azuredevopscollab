variable "rsgname" { }

variable "count_number" { }

variable "location" { }

variable "vnet_address" { }

variable "subnet_address" {  }

variable "vm_size" {  }

variable "tags" {
    type = map
/*    default = {
        Environment = "dev"
        Owner = "xyz"
        Company = "einfochips"
    }*/
}

variable "mysql_server_name" { }

variable "mysql_server_user" { }

variable "mysql_server_pass" { }

variable "ssh_port" { }

variable "ip_addresses" { }

variable "prefix" { }

variable "email_id" { }