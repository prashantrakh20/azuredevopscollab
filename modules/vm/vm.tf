resource "azurerm_availability_set" "example" {
  name                = "${var.prefix}-avlb"
  location            = var.location
  resource_group_name = var.rgname
  
  tags = var.tags    
}

resource "azurerm_public_ip" "lbpublicip" {
  name                = "PublicIPForLB"
  location            = var.location
  resource_group_name = var.rgname
  allocation_method   = "Static"
  
}

resource "azurerm_lb" "azurelb" {
  name                = "${var.prefix}-mylb"
  location            = var.location
  resource_group_name = var.rgname

  frontend_ip_configuration {
    name                 = "${var.prefix}-PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lbpublicip.id
  }
}

resource "azurerm_lb_backend_address_pool" "bpepool" {
  resource_group_name =  var.rgname
  loadbalancer_id     = azurerm_lb.azurelb.id
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "example" {
  resource_group_name = var.rgname
  loadbalancer_id     = azurerm_lb.azurelb.id
  name                = "ssh-running-probe"
  port                = 80
}

resource "azurerm_lb_rule" "example" {
  resource_group_name            = var.rgname
  loadbalancer_id                = azurerm_lb.azurelb.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "${var.prefix}-PublicIPAddress"
  backend_address_pool_id = azurerm_lb_backend_address_pool.bpepool.id
  probe_id = azurerm_lb_probe.example.id

}


resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "myPublicIP${count.index}"
    location                     = var.location
    resource_group_name          = var.rgname
    allocation_method            = "Static"
    tags = var.tags
    count=var.count_num
}


resource "azurerm_network_interface" "myterraformnic" {
    name                      = "myNIC${count.index}"
    location                  = var.location
    resource_group_name       = var.rgname

    ip_configuration {
        name                          = "myNicConfiguration${count.index}"
        subnet_id                     = var.subnet_id
        private_ip_address_allocation = "static"
        private_ip_address            = element(var.ip_addresses, count.index)
        public_ip_address_id          = length(azurerm_public_ip.myterraformpublicip.*.id) > 0 ? element(concat(azurerm_public_ip.myterraformpublicip.*.id, list("")), count.index) : ""
      }
    
        depends_on =[azurerm_public_ip.myterraformpublicip]
        tags = var.tags
        count=var.count_num

}

resource "azurerm_network_security_group" "aznwsg" {
    name                 = "${var.prefix}-mysng"
    location            = var.location
    resource_group_name = var.rgname
    
     security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    
    security_rule {
      name                       = "MySQL"
      priority                   = 111
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = 3306
      source_address_prefix      = "*"
      destination_address_prefix = "*"
  }

    tags = var.tags

}


resource "azurerm_network_interface_security_group_association" "example" {
    network_interface_id      = azurerm_network_interface.myterraformnic[count.index].id
    network_security_group_id = azurerm_network_security_group.aznwsg.id
    count=var.count_num
}



resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = var.rgname
    }
    
    byte_length = 8
}

resource "azurerm_storage_account" "mystorageaccount" {
    name                        = random_id.randomId.hex
    resource_group_name         = var.rgname
    location                    = var.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"
    tags = var.tags
}

resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "myterraformvm" {
    name                  = "myVM${count.index}"
    location              = var.location
    resource_group_name   = var.rgname
    count= var.count_num
    network_interface_ids =  [azurerm_network_interface.myterraformnic[count.index].id]
    size                  = var.vm_size
    availability_set_id   = azurerm_availability_set.example.id
    os_disk {
        name              = "myOsDisk${count.index}"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }
    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    computer_name  = "myvm${count.index}"
    admin_username = "redhat"
    disable_password_authentication = true
    
   admin_ssh_key {
        username       = "redhat"
        public_key     = tls_private_key.example_ssh.public_key_openssh
    }

    boot_diagnostics {
       
        storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
    }

   
    tags = var.tags
}


resource "null_resource" "configuration" {
  depends_on = [azurerm_linux_virtual_machine.myterraformvm, azurerm_public_ip.myterraformpublicip]
  connection {
        host = element(azurerm_public_ip.myterraformpublicip.*.ip_address, count.index) 
        user = "redhat"
        type = "ssh"
        private_key = tls_private_key.example_ssh.private_key_pem
        timeout = "2m"
        agent = false
        
    }

    provisioner "file" {
    source      = "../modules/vm/drupal.sh"
    destination = "/tmp/drupal.sh"
   }

     provisioner "remote-exec" {
        inline = [
          "chmod 777 /tmp/drupal.sh",
          "cd /tmp",
          "./drupal.sh ${var.mysql_server_name} ${var.mysql_server_user} ${var.mysql_server_pass} ${azurerm_public_ip.lbpublicip.ip_address}",
          "sudo chmod 777 /etc/ssh/sshd_config",
          "echo 'Port ${var.ssh_port}' >> /etc/ssh/sshd_config",
          "sudo service sshd restart"
        ]
    }
    count=var.count_num
}



resource "azurerm_network_interface_backend_address_pool_association" "example" {
  /*depends_on  = [null_resource.configuration]*/
  network_interface_id    = element(azurerm_network_interface.myterraformnic.*.id, count.index)
  ip_configuration_name   = "myNicConfiguration${count.index}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.bpepool.id
  count= var.count_num
}






