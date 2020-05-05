resource_group_name = "rg-bc-adhoc"
tags                = { owner = "Brendon Caligari", status = "in use" }
location            = "East US"
admin_user          = "sysop"
ssh_private_key     = "~/.credentials/id_rsa"
ssh_public_key      = "~/.credentials/id_rsa.pub"
instances           = 2
vm_size             = "Standard_B1s"
vm_image            = { publisher = "SUSE", offer = "sles-15-sp1-byos", sku = "gen2", version = "2020.02.26" }
tcp_ports           = ["22"]
udp_ports           = []
