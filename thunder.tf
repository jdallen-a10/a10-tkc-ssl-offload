#
#  SSL/HTTPS Demo
#
#  November, 2021
#

terraform {
  required_providers {
    thunder = {
      source = "a10networks/thunder"
      version = "0.5.18-beta"
    }
    linux = {
      source = "mavidser/linux"
      version = ">=1.0.2"
    }
  }
}

provider "thunder" {
  address = var.thunder_ip_address
  username = var.thunder_username
  password = var.thunder_password
  # partition = "shared"
}

resource "thunder_file_ssl_cert" "myapp-cert" {
  file = "myapp.pem"
  action = "import"
  certificate_type = "pem"
  file_handle = "myapp.pem"
  file_local_path = "./cert/myapp.pem"
}

resource "thunder_file_ssl_cert_key" "myapp-certkey" {
  file = "myapp-certkey"
  action = "import"
  file_handle = "myapp-certkey.tar"
  file_local_path = "./myapp-certkey.tar"
}

resource "thunder_slb_template_client_ssl" "inbound-ssl" {
  depends_on = [
    thunder_file_ssl_cert.myapp-cert,
    thunder_file_ssl_cert_key.myapp-certkey
  ]
  name = "inbound-ssl"
  certificate_list {
    cert = "myapp.pem"
    key = "myapp-key.pem"
  }
}

resource "thunder_slb_template_virtual_server" "bw-control" {
  name = "bw-control"
  conn_limit = 20
  conn_rate_limit = 20
}

resource "thunder_virtual_server" "ws-vip" {
  depends_on = [
    thunder_slb_template_virtual_server.bw-control
  ]
  name = "ws-vip"
  ip_address = var.thunder_vip
  template_virtual_server = "bw-control"
  port_list {
    port_number = 443
    protocol = "https"
    template_client_ssl = "inbound-ssl"
  }
}
