#!/usr/bin/env bash

set -euo pipefail

CONTAINER_NAME="jenkins"
JENKINS_PORT=8080
JENKINS_HEALTH_PATH="/login"
AWS_REGION="ap-south-1"
NAMESPACE="jenkins/OperationalMetrics"

# Get instance ID from IMDSv2 service
TOKEN=$(curl -sf -X PUT "http://169.254.169.254/latest/api/token" \
                 -H "X-aws-ec2-metadata-token-ttl-seconds: 60" || echo "")
echo $TOKEN

if [[ -z "$TOKEN" ]]; then
    echo "Failed to get IMDSv2 token"
    exit 1
fi
INSTANCE_ID=$(curl -sf -H "X-aws-ec2-metadata-token: $TOKEN" \
    http://169.254.169.254/latest/meta-data/instance-id)
echo $INSTANCE_ID   

# helper to put metrics
put_metric() {
    local metric_name="$1"
    local value="$2"
    local unit="${3:-None}"

    aws cloudwatch put-metric-data \
        --region "$AWS_REGION" \
        --namespace "$NAMESPACE" \
        --metric-data \
        "MetricName=${metric_name},Value=${value},Unit=${unit},Dimensions=[{Name=InstanceId,Value=${INSTANCE_ID}}]"
}

# Container running metrics
CONTAINER_STATUS=$(docker inspect --format='{{.State.Running}}' "$CONTAINER_NAME" 2>/dev/null || echo "false")
if [[ "$CONTAINER_STATUS" == "true" ]]; then
    CONTAINER_RUNNING=1
else
    CONTAINER_RUNNING=0
fi
put_metric "JenkinsContainerRunning" "$CONTAINER_RUNNING" "None"

# Jenkins HTTP endpoint healthy metrics
if [[ "$CONTAINER_RUNNING" -eq 1 ]]; then
    HTTP_CODE=$(curl -so /dev/null \
        -w "%{http_code}" \
        --connect-timeout 5 \
        --max-time 10 \
        "http://localhost:${JENKINS_PORT}${JENKINS_HEALTH_PATH}" || echo "000")

    if [[ "$HTTP_CODE" == "200" || "$HTTP_CODE" == "403" ]]; then
        JENKINS_HEALTHY=1
    else    
        JENKINS_HEALTHY=0
    fi
else
  JENKINS_HEALTHY=0
fi
put_metric "JenkinsHealthy" "$JENKINS_HEALTHY" "None"

# Container restart count metrics
RESTART_COUNT=$(docker inspect --format='{{.RestartCount}}' "$CONTAINER_NAME" 2>/dev/null || echo "0")
put_metric "JenkinsContainerRestartCount" "$RESTART_COUNT" "Count"

echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) InstanceId=${INSTANCE_ID} ContainerRunning=${CONTAINER_RUNNING} JenkinsHealthy=${JENKINS_HEALTHY} RestartCount=${RESTART_COUNT}"