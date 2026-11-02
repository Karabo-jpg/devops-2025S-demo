variable "image" {
  type        = string
  description = "Docker Hub image, e.g. youruser/campus-event-notifier:v1"
}

variable "container_port" {
  type    = number
  default = 8000
}

variable "external_port" {
  type    = number
  default = 8080
}

variable "container_name" {
  type    = string
  default = "campus-notifier-tf"
}
