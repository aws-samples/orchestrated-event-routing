output "ingress_queue" {
  value = aws_sqs_queue.ingress.url
}

output "service_a_queue" {
  value = aws_sqs_queue.service_a.url
}

output "service_b_queue" {
  value = aws_sqs_queue.service_b.url
}

output "service_c_queue" {
  value = aws_sqs_queue.service_c.url
}

output "service_d_queue" {
  value = aws_sqs_queue.service_d.url
}

output "service_e_queue" {
  value = aws_sqs_queue.service_e.url
}