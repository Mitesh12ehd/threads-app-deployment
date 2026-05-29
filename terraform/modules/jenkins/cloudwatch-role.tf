resource "aws_iam_role" "cw_agent" {
    name = "jenkins-cloudwatch-agent-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect    = "Allow"
            Principal = { Service = "ec2.amazonaws.com" }
            Action    = "sts:AssumeRole"
        }]
    })

    tags = {
        Name = "jenkins-cloudwatch-agent-role"
    }
} 

resource "aws_iam_role_policy_attachment" "cw_agent_policy" {
    role = aws_iam_role.cw_agent.name
    policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy" "ssm_read_agent_config" {
    name = "jenkins-ssm-read-agent-config"
    role = aws_iam_role.cw_agent.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Sid = "ReadAgentConfig"
            Effect = "Allow"
            Action = [
                "ssm:GetParameter",
                "ssm:GetParameters"
            ]
            # here name should be match with created ssm parameter
            Resource = "arn:aws:ssm:*:*:parameter/AmazonCloudWatch-jenkins*"
        }]
    })
}

resource "aws_iam_instance_profile" "cw_agent" {
    name = "jenkins-cloudwatch-agent-profile"
    role = aws_iam_role.cw_agent.name
    
    tags = {
        Name = "jenkins-cloudwatch-agent-profile"
    }
}