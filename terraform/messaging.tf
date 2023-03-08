// ---------------------------------------------------------------------------
// ----------------================ MESSAGING ================----------------
// ---------------------------------------------------------------------------

// Ingress Queue
resource "aws_sqs_queue" "ingress" {
  name = var.ingress_queue_name
}

// Egress event bus
resource "aws_cloudwatch_event_bus" "egress" {
  name = var.egress_bus_name
}

// Create a rule that routes all logs to cloudwatch for debugging
resource "aws_cloudwatch_event_rule" "route_all_cloudwatch" {
  name           = "route-all-cloudwatch"
  description    = "route a copy of all messages to cloudwatch for logging"
  event_bus_name = aws_cloudwatch_event_bus.egress.name
  event_pattern  = "{ \"account\": [\"${data.aws_caller_identity.current.account_id}\"] }"
}

resource "aws_cloudwatch_log_group" "egress" {
  name              = "/aws/events/${var.egress_bus_name}"
  retention_in_days = 1
}

resource "aws_cloudwatch_event_target" "cloudwatch" {
  event_bus_name = aws_cloudwatch_event_bus.egress.name
  rule           = aws_cloudwatch_event_rule.route_all_cloudwatch.name
  arn            = aws_cloudwatch_log_group.egress.arn
}


// ---------------------------------------------------------------------------
// Service A
// ---------------------------------------------------------------------------

resource "aws_sqs_queue" "service_a" {
  name = "service-a"
}

resource "aws_cloudwatch_event_rule" "service_a" {
  name           = "route-service-a"
  description    = "route notifications to service-a target queue"
  event_bus_name = aws_cloudwatch_event_bus.egress.name
  event_pattern  = <<EOF
{
  "detail": { 
    "notifyServices": ["Service A"]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "service_a_queue" {
  event_bus_name = aws_cloudwatch_event_bus.egress.name
  rule           = aws_cloudwatch_event_rule.service_a.name
  arn            = aws_sqs_queue.service_a.arn
  input_path     = "$.detail"
}

data "aws_iam_policy_document" "write_to_service_a_queue" {
  statement {
    sid    = "writeToServiceAQueue"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.service_a.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.service_a.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "service_a_access_policy" {
  queue_url = aws_sqs_queue.service_a.id
  policy    = data.aws_iam_policy_document.write_to_service_a_queue.json
}

// ---------------------------------------------------------------------------
// Service B
// ---------------------------------------------------------------------------
resource "aws_sqs_queue" "service_b" {
  name = "service-b"
}

resource "aws_cloudwatch_event_rule" "service_b" {
  name           = "route-service-b"
  description    = "route notifications to service-b target queue"
  event_bus_name = aws_cloudwatch_event_bus.egress.name
  event_pattern  = <<EOF
{
  "detail": { 
    "notifyServices": ["Service B"]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "service_b_queue" {
  event_bus_name = aws_cloudwatch_event_bus.egress.name
  rule           = aws_cloudwatch_event_rule.service_b.name
  arn            = aws_sqs_queue.service_b.arn
  input_path     = "$.detail"
}

data "aws_iam_policy_document" "write_to_service_b_queue" {
  statement {
    sid    = "writeToServiceBQueue"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.service_b.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.service_b.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "service_b_access_policy" {
  queue_url = aws_sqs_queue.service_b.id
  policy    = data.aws_iam_policy_document.write_to_service_b_queue.json
}

// ---------------------------------------------------------------------------
// Service C
// ---------------------------------------------------------------------------
resource "aws_sqs_queue" "service_c" {
  name = "service-c"
}

resource "aws_cloudwatch_event_rule" "service_c" {
  name           = "route-service-c"
  description    = "route notifications to service-c target queue"
  event_bus_name = aws_cloudwatch_event_bus.egress.name
  event_pattern  = <<EOF
{
  "detail": { 
    "notifyServices": ["Service C"]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "service_c_queue" {
  event_bus_name = aws_cloudwatch_event_bus.egress.name
  rule           = aws_cloudwatch_event_rule.service_c.name
  arn            = aws_sqs_queue.service_c.arn
  input_path     = "$.detail"
}

data "aws_iam_policy_document" "write_to_service_c_queue" {
  statement {
    sid    = "writeToServiceCQueue"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.service_c.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.service_c.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "service_c_access_policy" {
  queue_url = aws_sqs_queue.service_c.id
  policy    = data.aws_iam_policy_document.write_to_service_c_queue.json
}

// ---------------------------------------------------------------------------
// Service D
// ---------------------------------------------------------------------------
resource "aws_sqs_queue" "service_d" {
  name = "service-d"
}

resource "aws_cloudwatch_event_rule" "service_d" {
  name           = "route-service-d"
  description    = "route notifications to service-d target queue"
  event_bus_name = aws_cloudwatch_event_bus.egress.name
  event_pattern  = <<EOF
{
  "detail": { 
    "notifyServices": ["Service D"]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "service_d_queue" {
  event_bus_name = aws_cloudwatch_event_bus.egress.name
  rule           = aws_cloudwatch_event_rule.service_d.name
  arn            = aws_sqs_queue.service_d.arn
  input_path     = "$.detail"
}

data "aws_iam_policy_document" "write_to_service_d_queue" {
  statement {
    sid    = "writeToServiceDQueue"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.service_d.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.service_d.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "service_d_access_policy" {
  queue_url = aws_sqs_queue.service_d.id
  policy    = data.aws_iam_policy_document.write_to_service_d_queue.json
}

// ---------------------------------------------------------------------------
// Service E
// ---------------------------------------------------------------------------
resource "aws_sqs_queue" "service_e" {
  name = "service-e"
}

resource "aws_cloudwatch_event_rule" "service_e" {
  name           = "route-service-e"
  description    = "route notifications to service-e target queue"
  event_bus_name = aws_cloudwatch_event_bus.egress.name
  event_pattern  = <<EOF
{
  "detail": { 
    "notifyServices": ["Service E"]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "service_e_queue" {
  event_bus_name = aws_cloudwatch_event_bus.egress.name
  rule           = aws_cloudwatch_event_rule.service_e.name
  arn            = aws_sqs_queue.service_e.arn
  input_path     = "$.detail"
}

data "aws_iam_policy_document" "write_to_service_e_queue" {
  statement {
    sid    = "writeToServiceEQueue"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.service_e.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.service_e.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "service_e_access_policy" {
  queue_url = aws_sqs_queue.service_e.id
  policy    = data.aws_iam_policy_document.write_to_service_e_queue.json
}
