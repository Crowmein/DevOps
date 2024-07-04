terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  service_account_key_file = "authorized_key.json"
  cloud_id                 = "b1gvo0u9846h7cfi2adh"
  folder_id                = "b1gviv9gu1amglm0ekk2"
  zone                     = "ru-central1-a"
}