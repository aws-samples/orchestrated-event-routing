// ----------------------------------------------------------------------------
// Policy for putting events to EventBridge
// ----------------------------------------------------------------------------
data "aws_iam_policy_document" "eventbridge_access" {
  statement {
    sid = "2"
    actions = [
      "events:PutEvents",
    ]
    resources = [
      aws_cloudwatch_event_bus.egress.arn
    ]
  }
}

resource "aws_iam_policy" "eventbridge_access" {
  name   = "eventbridge-access-policy"
  policy = data.aws_iam_policy_document.eventbridge_access.json
}

// ----------------------------------------------------------------------------
// Policy for receiving messages from SQS
// ----------------------------------------------------------------------------
data "aws_iam_policy_document" "sqs_access" {
  statement {
    sid = "1"
    actions = [
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage"
    ]
    resources = [
      aws_sqs_queue.ingress.arn
    ]
  }
}

// creates a policy from the document
resource "aws_iam_policy" "sqs_access" {
  name   = "lambda-execution-policy"
  policy = data.aws_iam_policy_document.sqs_access.json
}

