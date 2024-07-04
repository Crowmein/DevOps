resource "yandex_vpc_network" "network_srv" {
  name = "net_srv"
}

resource "yandex_vpc_subnet" "subnet_srv" {
  name           = "sabnet_srv"
  v4_cidr_blocks = ["10.2.0.0/16"]
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network_srv.id
}

resource "yandex_vpc_security_group" "sec_srv" {
  name        = "sec_group_srv"
  description = ""
  network_id  = yandex_vpc_network.network_srv.id

  labels = {
    my-label = ""
  }

  dynamic "ingress" {
    for_each = ["22", "80", "443","2049", "3000", "8080", "9090", "9100"]
    content {
      protocol       = "TCP"
      description    = ""
      v4_cidr_blocks = ["0.0.0.0/0"]
      from_port      = ingress.value
      to_port        = ingress.value
    }
  }

  egress {
    protocol       = "ANY"
    description    = ""
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_vpc_address" "address_srv" {
  name = "addr_srv"

  external_ipv4_address {
    zone_id = "ru-central1-a"
  }
}

resource "yandex_compute_instance" "ubuntu" {
  name               = "srv"
  platform_id        = "standard-v1"
  service_account_id = "ajepskhoj4vjd6918otb"

  resources {
    cores  = 4
    memory = 4
  }

  boot_disk {
    initialize_params {
      type     = "network-hdd"
      size     = 64
      image_id = "fd82q139jila6qj302bs"
      name     = "ubuntu"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet_srv.id
    nat                = true
    nat_ip_address     = yandex_vpc_address.address_srv.external_ipv4_address.0.address
    security_group_ids = [yandex_vpc_security_group.sec_srv.id]
  }

  metadata = {
    user-data = "${file("cloud_config.yaml")}"
  }
  connection {
    type        = "ssh"
    user        = "admins"
    private_key = file("/root/.ssh/id_ed25519")
    host        = self.network_interface.0.nat_ip_address
  }

  provisioner "remote-exec" {
    script = "/home/admins/Git/Scripts/full.sh" 
  }
}
output "external_ip" {
  value = yandex_vpc_address.address_srv.external_ipv4_address.0.address
}