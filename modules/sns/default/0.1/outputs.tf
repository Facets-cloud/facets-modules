locals {
  output_interfaces = {}
  output_attributes = {
    sns_topic_name      = module.sns.topic_name
    consumer_policy_arn = aws_iam_policy.consumer_policy.arn
    producer_policy_arn = aws_iam_policy.producer_policy.arn
    topic_arn           = module.sns.topic_arn
    topic_name          = module.sns.topic_name
  }
}