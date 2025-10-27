variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
  default     = "b1g1i379knkknb9igf9n"
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
  default     = "b1g0aqak1gboqujsjqga"
}

variable "zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["ru-central1-a", "ru-central1-b"]
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "preemptible" {
  description = "Использовать прерываемые (дешёвые) ВМ. true = прерываемые, false = обычные ВМ"
  type        = bool
  default     = true
}
