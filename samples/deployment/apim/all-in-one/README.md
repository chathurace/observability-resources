## Deploy WSO2 APIM all-in-one

Run the following command from this directory.

```
helm install wso2-apim . -n observability
```


## Accessing APIM Publisher & DevPortal

Please follow these steps to access API Manager Publisher, DevPortal consoles.

1. Obtain the external IP (`EXTERNAL-IP`) of the API Manager Ingress resources, by listing down the Kubernetes Ingresses.

  kubectl get ing -n observability

  The output under the relevant column stands for the following.

  API Manager Publisher-DevPortal

  - NAME: Metadata name of the Kubernetes Ingress resource (defaults to wso2-apim-am-all-in-one-am-ingress)
  - HOSTS: Hostname of the WSO2 API Manager service (am.wso2.com)
  - ADDRESS: External IP (`EXTERNAL-IP`) exposing the API Manager service to outside of the Kubernetes environment
  - PORTS: Externally exposed service ports of the API Manager service

  API Manager Gateway

  - NAME: Metadata name of the Kubernetes Ingress resource (defaults to wso2-apim-am-all-in-one-am-gateway-ingress)
  - HOSTS: Hostname of the WSO2 API Manager's Gateway service (gw.wso2.com)
  - ADDRESS: External IP (`EXTERNAL-IP`) exposing the API Manager's Gateway service to outside of the Kubernetes environment
  - PORTS: Externally exposed service ports of the API Manager' Gateway service


2. Add a DNS record mapping the hostnames (in step 1) and the external IP.

   If the defined hostnames (in step 1) are backed by a DNS service, add a DNS record mapping the hostnames and
   the external IP (`EXTERNAL-IP`) in the relevant DNS service.

   If the defined hostnames are not backed by a DNS service, for the purpose of evaluation you may add an entry mapping the
   hostnames and the external IP in the `/etc/hosts` file at the client-side.

   <EXTERNAL-IP> am.wso2.com gw.wso2.com

3. Navigate to the consoles in your browser of choice.

   API Manager Publisher: https://am.wso2.com/publisher
   API Manager DevPortal: https://am.wso2.com/devportal


   ## Enabling Correlation Logs

   Execute the following cURL command.
   ```
   curl -X PUT 'https://am.wso2.com/api/am/devops/v0/config/correlation' \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -H 'Authorization: Basic YWRtaW46YWRtaW4=' \
    -d '{"components":[{
        "name":"http",
        "enabled":"true"},
        {
        "name":"ldap",
        "enabled":"false"},
        {
        "name":"jdbc",
        "enabled":"false"},
        {
        "name":"synapse",
        "enabled":"true"},
        {
        "name":"method-calls",
        "enabled":"false"}]}' -k
   ```