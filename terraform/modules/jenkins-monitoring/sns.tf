resource "aws_sns_topic" "critical" {
    name = "jenkins-alert-critical"
    
    tags = {
        Name = "jenkins-alert-critical"
    }
}  

resource "aws_sns_topic_subscription" "critical_email" {
    topic_arn = aws_sns_topic.critical.arn
    protocol = "email"
    endpoint = var.alert_email
}

resource "aws_sns_topic" "warning" {
    name = "jenkins-alert-warning"
    tags = {
        Name = "jenkins-alert-warning"
    }
}

resource "aws_sns_topic_subscription" "warning_email" {
    topic_arn = aws_sns_topic.warning.arn
    protocol = "email"
    endpoint = var.alert_email
}