provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

// ----------------================ SECURITY GROUPS ================----------------
resource "aws_security_group" "application" {
  name        = "application"
  description = "contains application components"
  vpc_id      = var.vpc_id

  ingress {
    description = "allow all communication within the security group"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    self        = true
  }

  egress {
    description = "allow all egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "database" {
  name        = "database"
  description = "contains neptune database"
  vpc_id      = var.vpc_id

  ingress {
    description     = "allow all communication to neptune on 8182 from the application security group"
    from_port       = 8182
    to_port         = 8182
    protocol        = "TCP"
    security_groups = [aws_security_group.application.id]
  }

  egress {
    description = "allow all egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
