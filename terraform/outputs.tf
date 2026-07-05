output "app_server_public_ip" {
  description = "Public IP of the k3s app server"
  value       = aws_instance.app_server.public_ip
}

output "jenkins_server_public_ip" {
  description = "Public IP of the Jenkins server"
  value       = aws_instance.jenkins_server.public_ip
}

output "ecr_repository_url" {
  description = "ECR repo URL to push Docker images to"
  value       = aws_ecr_repository.app.repository_url
}

output "app_url" {
  description = "URL to access the app once k3s + deployment are up"
  value       = "http://${aws_instance.app_server.public_ip}:30080"
}

output "grafana_url" {
  description = "URL to access Grafana once monitoring stack is deployed"
  value       = "http://${aws_instance.app_server.public_ip}:30300"
}
