resource "aws_iam_role" "lambda_execution_role" {
  name               = "lambda-execution-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      }
    }
  ]
}
EOF
}

resource "null_resource" "install_dependencies" {
  provisioner "local-exec" {
    command = "pip3 install -r ./lambda/requirements.txt -t ./lambda/ --upgrade"
  }

  triggers = {
    dependencies_versions = filemd5("./lambda/requirements.txt")
  }
}

data "archive_file" "zip" {
  depends_on  = [null_resource.install_dependencies]
  type        = "zip"
  source_dir  = "./lambda"
  output_path = "./out/lambda.zip"
  excludes = [
    "__pycache__"
  ]
}

resource "aws_lambda_function" "main" {
  function_name    = var.lambda_name
  filename         = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256

  role    = aws_iam_role.lambda_execution_role.arn
  handler = "lambda.lambda_handler"
  runtime = "python3.9"
  timeout = 30

  environment {
    variables = {
      GRAPH_URI      = aws_neptune_cluster_instance.main[0].endpoint,
      EVENT_BUS_NAME = aws_cloudwatch_event_bus.egress.name
      EVENT_SCHEMA   = "resource-changed"
      ALGORITHM      = var.algorithm
    }
  }

  vpc_config {
    subnet_ids         = var.vpc_subnets_private_ids
    security_group_ids = [aws_security_group.application.id]
  }
}

resource "aws_lambda_event_source_mapping" "trigger" {
  event_source_arn = aws_sqs_queue.ingress.arn
  enabled          = true
  function_name    = aws_lambda_function.main.arn
  batch_size       = 1
}

// attaches the policy that allows the lambda to access sqs
resource "aws_iam_role_policy_attachment" "sqs_access" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.sqs_access.arn
}

// attaches the policy that allows the lambda to access eventbridge
resource "aws_iam_role_policy_attachment" "eventBridgeAccess" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.eventbridge_access.arn
}

// attaches the aws managed policy for lambda-in-vpc execution to the role
resource "aws_iam_role_policy_attachment" "awsManagedLambdaVPCExecution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.lambda_name}"
  retention_in_days = 1
}

resource "aws_vpc_endpoint" "events" {
  vpc_id              = var.vpc_id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.events"
  security_group_ids  = [aws_security_group.application.id]
  subnet_ids          = var.vpc_subnets_private_ids
  private_dns_enabled = true
}
