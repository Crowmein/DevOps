resource "yandex_vpc_network" "network_kuber" {
  name = "network_kuber"
}

resource "yandex_vpc_subnet" "subnet_kuber_a" {
  name           = "sub_k8s_a"
  v4_cidr_blocks = ["10.5.0.0/16"]
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network_kuber.id
}

resource "yandex_vpc_subnet" "subnet_kuber_b" {
  name           = "sub_k8s_b"
  v4_cidr_blocks = ["10.6.0.0/16"]
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network_kuber.id
}

resource "yandex_vpc_subnet" "subnet_suber_d" {
  name           = "sub_k8s_d"
  v4_cidr_blocks = ["10.7.0.0/16"]
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.network_kuber.id
}

resource "yandex_vpc_security_group" "secutity_kuber" {
  name        = "sec_k8s"
  network_id  = yandex_vpc_network.network_kuber.id
  ingress {
    protocol          = "TCP"
    predefined_target = "loadbalancer_healthchecks"
    from_port         = 0
    to_port           = 65535
  }
  ingress {
    protocol          = "ANY"
    predefined_target = "self_security_group"
    from_port         = 0
    to_port           = 65535
  }
  ingress {
    protocol       = "ANY"
    v4_cidr_blocks = concat(yandex_vpc_subnet.subnet_kuber_a.v4_cidr_blocks, yandex_vpc_subnet.subnet_kuber_b.v4_cidr_blocks, yandex_vpc_subnet.subnet_suber_d.v4_cidr_blocks)
    from_port      = 0
    to_port        = 65535
  }
  ingress {
    protocol       = "ICMP"
    v4_cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }
  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 30000
    to_port        = 32767
  }

    ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 3003
  }

    ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }
  
  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_kms_symmetric_key" "kms-key" {
  name              = "kms-key"
  default_algorithm = "AES_128"
  rotation_period   = "8760h" # 1 год.
}

resource "yandex_kubernetes_cluster" "cluster-k8s" {
  name                    = "k8s"
  network_id              = yandex_vpc_network.network_kuber.id
  network_policy_provider = "CALICO"
  master {
    public_ip = true
    master_location {
      zone      = yandex_vpc_subnet.subnet_kuber_a.zone
      subnet_id = yandex_vpc_subnet.subnet_kuber_a.id
    }
    master_location {
      zone      = yandex_vpc_subnet.subnet_kuber_b.zone
      subnet_id = yandex_vpc_subnet.subnet_kuber_b.id
    }
    master_location {
      zone      = yandex_vpc_subnet.subnet_suber_d.zone
      subnet_id = yandex_vpc_subnet.subnet_suber_d.id
    }
    security_group_ids = [yandex_vpc_security_group.secutity_kuber.id]
  }
  service_account_id      = "ajepskhoj4vjd6918otb"
  node_service_account_id = "ajepskhoj4vjd6918otb"

  kms_provider {
    key_id = yandex_kms_symmetric_key.kms-key.id
  }
}

resource "yandex_kubernetes_node_group" "my_node_group_a" {
  cluster_id = yandex_kubernetes_cluster.cluster-k8s.id
  name       = "prod-a"
  version    = "1.27"

  labels = {
    "key" = "value"
  }

  instance_template {
    platform_id = "standard-v1"
    name        = "prod-a-{instance.index}"

    network_interface {
      nat                = true
      subnet_ids         = ["${yandex_vpc_subnet.subnet_kuber_a.id}"]
      security_group_ids = [yandex_vpc_security_group.secutity_kuber.id]
    }

    resources {
      memory = 4
      cores  = 4
    }

    boot_disk {
      type = "network-hdd"
      size = 32
    }

    scheduling_policy {
      preemptible = false
    }
  }

  scale_policy {
    auto_scale {
      min     = 1
      max     = 3
      initial = 1
    }
  }

  allocation_policy {
    location {
      zone = "ru-central1-a"
    }
  }
}