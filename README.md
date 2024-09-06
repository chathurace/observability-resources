# WSO2 Integration Observability Solution

## Pre-requisites
- Kubernetes cluster
- Helm

## Deployment

1. Clone this repository to a local folder. Local repository path is shown as `<repo-path>` in remaining sections.

2. Create a Kubernetes namespace named "observability"
```
kubectl create ns observability
```

3. Deploy the OpenSearch operator using the following commands:
```
helm repo add opensearch-operator https://opensearch-project.github.io/opensearch-k8s-operator/
helm repo update
helm install opensearch-operator opensearch-operator/opensearch-operator -n observability --version 2.6.1
```

4. Deploy the OpenSearch cluster using the below command: 
```
kubectl apply -f <repo-path>/observability/deployment/opensearch.yaml
``` 
It will take few minutes to deploy all components of the cluster. Deployment staus can be monitored using the `kubectl get pods -n observability` command. All opensearch pods except the *opensearch-securityconfig* will be in *Ready* state once the deployment is complete.

5. Configure a port forwarding to the Open Search dashboard.
```
kubectl port-forward svc/opensearch-dashboards 5601:5601 -n observability
```

6. Deploy the fluent-bit agent using the following commands:
```
helm repo add fluent https://fluent.github.io/helm-charts
helm repo update
helm install fluent-bit fluent/fluent-bit --version 0.43.0 -n observability -f <repo-path>/observability/deployment/fluent-bit.yaml
```

7. Deploy Data Prepper by running the following command from the `<repo-path>/observability/deployment/` directory:
```
helm install wso2-observability wso2-observability
```

7. Follow the following steps to deploy integration dashboards:
    1. Log in to the OpenSearch dashboard at URL [http://localhost:5601](http://localhost:5601) using the default credentials *(username: admin, password: admin)*
    2. Navigate to *Dashboard management -> Saved objects* menu
    3. Click *Import* link and import the `<repo-path>/observability/dashboards/integration-dashboards.ndjson` file.
    4. Navigate to *Dashbaords* menu and you will see two dashbaords for WSO2 Micro Integrator and Ballerina.
    5. Navigate to the *Traces* menu under the *Observability* section to see trace analytics.

## Trying out the solution

A set of sample Ballerina and Micro Integrator deployments are included to try out this solution. These samples generate logs with different log levels depending on the request payload.

1. Navigate to the `<repo-path>/samples` folder and execute `sh deploy_samples.sh`. This will build and deploy all samples in the Kubernetes cluster.

2. Port forward 8290 and 9100, which are used by MI and Ballerina deployments.
```
kubectl port-forward svc/bookpark-svc 8290:8290
kubectl port-forward svc/portal-svc 9100:9100
```

3. Import `<repo-path>/samples/postman/Integration_Observability.postman_collection.json` to Postman. This contains various requests that cause deployed MI and Ballerina pods to emit different log messages.

4. Navigate to `Dashboards -> Ballerina - Dashboard` in the OpenSearch portal to view log analytics of Ballerina pods.

5. Navigate to `Dashboards -> MI - Dashboard` in the OpenSearch portal to view log analytics of MI pods.

6. Navigate to the `Traces` menu under the `Observability` section to see traces and service maps derived from traces.
