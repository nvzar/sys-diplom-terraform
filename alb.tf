# Target Group
resource "yandex_alb_target_group" "web-tg" {
  name      = "web-target-group"
  folder_id = var.folder_id

  target {
    subnet_id  = yandex_vpc_subnet.private-subnet-a.id
    ip_address = yandex_compute_instance.web-1.network_interface.0.ip_address
  }

  target {
    subnet_id  = yandex_vpc_subnet.private-subnet-b.id
    ip_address = yandex_compute_instance.web-2.network_interface.0.ip_address
  }
}

# Backend Group
resource "yandex_alb_backend_group" "web-bg" {
  name      = "web-backend-group"
  folder_id = var.folder_id

  http_backend {
    name             = "web-backend"
    weight           = 1
    target_group_ids = [yandex_alb_target_group.web-tg.id]
    load_balancing_config {
      panic_threshold = 90
    }
    healthcheck {
      timeout             = "10s"
      interval            = "2s"
      healthy_threshold   = 10
      unhealthy_threshold = 2
      http_healthcheck {
        path = "/"
      }
    }
  }
}

# HTTP Router
resource "yandex_alb_http_router" "web-router" {
  name      = "web-http-router"
  folder_id = var.folder_id
}

# Virtual Host
resource "yandex_alb_virtual_host" "web-vh" {
  name           = "web-virtual-host"
  http_router_id = yandex_alb_http_router.web-router.id

  route {
    name = "web-route"
    http_route {
      http_match {
        path {
          prefix = "/"
        }
      }
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web-bg.id
      }
    }
  }
}

# Load Balancer
resource "yandex_alb_load_balancer" "web-alb" {
  name       = "web-load-balancer"
  folder_id  = var.folder_id
  network_id = yandex_vpc_network.diplom-network.id

  allocation_policy {
    location {
      zone_id   = var.zones[0]
      subnet_id = yandex_vpc_subnet.public-subnet.id
    }
  }

  listener {
    name = "web-listener"
    endpoint {
      address {
        external_ipv4_address {}
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.web-router.id
      }
    }
  }
}
