output "result" {
  description = "The generated random string"
  value       = random_string.this.result
}

output "id" {
  description = "The ID of the random string resource"
  value       = random_string.this.id
}