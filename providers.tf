terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.100"
    }
  }
  required_version = ">= 1.0"
}

provider "yandex" {
  service_account_key_file = pathexpand("~/sa-key.json")
  cloud_id                 = "b1g1i379knkknb9igf9n"
  folder_id                = "b1g0aqak1gboqujsjqga"
  zone                     = "ru-central1-a"
}
