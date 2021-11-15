
provider "linux" {
  host = "10.14.5.220"
  user = "root"
  password = "mypasswd"
}

resource "linux_file" "DEMO" {
  path = "/tmp/DEMO.ID"
  content = "lt:terraform/tkd-ssl-offload-demo-k8s\n"
}

