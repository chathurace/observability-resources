#!/bin/bash

# Create the Kubernetes namespace
echo "Creating Kubernetes namespace 'observability'..."
kubectl create ns observability

# Deploy the OpenSearch operator
echo "Deploying the OpenSearch operator..."
helm repo add opensearch-operator https://opensearch-project.github.io/opensearch-k8s-operator/
helm repo update
helm upgrade --install opensearch-operator opensearch-operator/opensearch-operator -n observability --version 2.6.1
if [[ $? -ne 0 ]]; then
  echo "ERROR: Failed to intall the OpenSearch operator."
  exit 1
fi

# Wait for the OpenSearch operator to be fully deployed
echo "Waiting for OpenSearch operator pods to be ready..."
while [[ $(kubectl get pods -n observability | grep -c "opensearch-operator.*Running") -lt 1 ]]; do
  echo "Waiting for the OpenSearch operator pod to be ready..."
  sleep 10
done
echo "OpenSearch operator deployed successfully."

# Deploy the OpenSearch cluster
echo "Deploying the OpenSearch cluster..."
kubectl apply -f deployment/opensearch.yaml
if [[ $? -ne 0 ]]; then
  echo "ERROR: Failed to deploy the OpenSearch cluster."
  exit 1
fi

# Function to check if all conditions are met
function check_pod_status() {
  # Check if opensearch-securityconfig pod is in Completed state
  securityconfig_status=$(kubectl get pod -n observability | grep "opensearch-securityconfig" | awk '{print $3}')
  if [[ "$securityconfig_status" != "Completed" ]]; then
    return 1
  fi

  # Check if all other pods starting with "opensearch" are in Ready state
  # i.e., if READY column shows the same number for both containers ready and total containers
  all_pods_ready=$(kubectl get pods -n observability | grep "^opensearch" | grep -v "opensearch-securityconfig" | awk '{print $2}' | awk -F'/' '$1 == $2' | wc -l)
  total_other_pods=$(kubectl get pods -n observability | grep "^opensearch" | grep -v "opensearch-securityconfig" | wc -l)

  # Ensure the number of pods that are fully ready matches the total number of pods
  if [[ "$all_pods_ready" -eq "$total_other_pods" ]]; then
    return 0
  else
    return 1
  fi
}

# Loop until all conditions are met
until check_pod_status; do
  echo "Waiting for OpenSearch cluster to be ready. This may take few minutes..."
  sleep 60
done

echo "OpenSearch cluster deployed successfully."

# Deploy the Fluent Bit agent
echo "Deploying Fluent Bit agent..."
helm repo add fluent https://fluent.github.io/helm-charts
helm repo update
helm upgrade --install fluent-bit fluent/fluent-bit --version 0.43.0 -n observability -f deployment/fluent-bit.yaml
if [[ $? -ne 0 ]]; then
  echo "ERROR: Failed to deploy the Fluent Bit agent."
  exit 1
fi

# Deploy Data Prepper
# echo "Deploying Data Prepper..."
# helm install wso2-observability deployment/wso2-observability -n observability

echo "WSO2 observability resources deployed successfully."

# Configure port forwarding for OpenSearch Server
echo "Setting up port forwarding to OpenSearch Server..."
kubectl port-forward svc/opensearch-data 9200:9200 -n observability &

# Configure port forwarding for OpenSearch Dashboards
echo "Setting up port forwarding to OpenSearch Dashboards..."
kubectl port-forward svc/opensearch-dashboards 5601:5601 -n observability &

# Create WSO2 integration dashboards
URL="http://localhost:5601/api/saved_objects/_import"
USERNAME="admin"
PASSWORD="admin"
INTEGRATION_DASHBOARDS="dashboards/opensearch-artifacts.ndjson"

curl -X POST "$URL" -u "$USERNAME:$PASSWORD" -H "osd-xsrf: true" -F file=@$INTEGRATION_DASHBOARDS --insecure

if [[ $? -eq 0 ]]; then
  echo "WSO2 integration dashboards created successfully."
else
  echo "Failed to create WSO2 integration dashboards."
  exit 1
fi

# Create index template for integration logs
URL="https://localhost:9200/_index_template/wso2_integration_log_template"
USERNAME="admin"
PASSWORD="admin"
INDEX_TEMPLATE_REQUEST="dashboards/index-template-request.json"

curl -X PUT "$URL" -u "$USERNAME:$PASSWORD" -H "Content-Type: application/json" -d "@$INDEX_TEMPLATE_REQUEST" --insecure

if [[ $? -eq 0 ]]; then
  echo "Index template for WSO2 integration logs created successfully."
else
  echo "Failed to create index template for WSO2 integration logs."
  exit 1
fi

echo "OpenSearch dashboards configured successfully."




