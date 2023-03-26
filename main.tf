
#Create ECR repository
resource "aws_ecr_repository" "demo_repo" {
  name = "container_registry_demo"
}

# Define the ECS cluster
resource "aws_ecs_cluster" "demo_cluster" {
  name = "ECS_cluster_demo"
}

# Define the Fargate task definition
resource "aws_ecs_task_definition" "demo_task_definition" {
  family                   = "PearlThoughts-task-demo"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions    = jsonencode([
    {
      name                  = "container_demo"
      image                 = "${aws_ecr_repository.demo_repo.repository_url}:latest"
      portMappings          = [
        {
          containerPort     = 3000
          hostPort          = 3000
          protocol          = "tcp"
        }
      ]
    }
  ])
}


# Define the Fargate service
resource "aws_ecs_service" "demo_service" {
  name            = "demo-service"
  cluster         = aws_ecs_cluster.demo_cluster.id
  task_definition = aws_ecs_task_definition.demo_task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  deployment_controller {
    type = "ECS"
  }


  network_configuration {
    subnets            = [aws_subnet.private.*.id[0]]
    security_groups    = [aws_security_group.ecs_service.id]
    assign_public_ip   = false
  }
}


resource "aws_security_group" "ecs_service" {
  name_prefix = "ecs_service_"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_subnet" "private" {
  count = 2

  cidr_block = "10.0.${count.index + 1}.0/24"
}
