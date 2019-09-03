# Debug and troubleshooting TLS

This guide is [based on cert manager quickstart guide](https://github.com/jetstack/cert-manager/blob/master/docs/tutorials/acme/quick-start/index.rst), to help you debug when setting up TLS w/ cert manager and letsencrypt.

## Look at nginx logging, in realtime

`bash ./my-kubectl.sh logs --follow ds/nginx-ingress-controller -n kube-system`

## Look at cert manager logging, in realtime

`bash ./my-kubectl.sh logs --follow  $(bash ./my-kubectl.sh get pods -n cert-manager | grep cert-manager --max-count=1 | awk '{print $1}') -n cert-manager`

Does cert manager started working on certificate? It should generate a lot of log more than 15 lines.


## Check out certificate

`. ./my-kubectl.sh get certificate --all-namespaces`

Does it show the `READY` column as `True`?

`bash ./my-kubectl.sh describe certificate letsencrypt-staging-secret -n cicd-django`

Check the event log on certificate, does it show something like below?

```
Events:
  Type     Reason              Age                  From          Message
  ----     ------              ----                 ----          -------
  Warning  IssuerNotReady      4m1s (x2 over 4m1s)  cert-manager  Issuer letsencrypt-staging-issuer not ready
  Normal   Generated           4m                   cert-manager  Generated new private key
  Normal   GenerateSelfSigned  4m                   cert-manager  Generated temporary self signed certificate
  Normal   OrderCreated        4m                   cert-manager  Created Order resource "letsencrypt-staging-secret-3778618215"
  Normal   OrderComplete       2m22s                cert-manager  Order "letsencrypt-staging-secret-3778618215" completed successfully
  Normal   CertIssued          2m22s                cert-manager  Certificate issued successfully
```

## Check out the secrets for letsencrypt, and secrets for ingress tls

`. ./my-kubectl.sh get secrets --all-namespaces`

About secret type - the secret [on the ing is `kubernetes.io/tls`](https://github.com/jetstack/cert-manager/blob/master/docs/tutorials/acme/quick-start/index.rst#step-7---deploy-a-tls-ingress-resource), which is fine. The secret for letsencrypt api call private key should be `Opaque`.


## Hit the website

`curl -vkI https://shaungc.com` (TLD)
`curl -vkI https://api.shaungc.com` (2LD)
`curl -vkI https://appl-tracky.api.shaungc.com` (3rd level)

For staging, does it show something like below?

```
...
* Server certificate:
*  subject: CN=*.shaungc.com
*  start date: Sep  1 22:55:32 2019 GMT
*  expire date: Nov 30 22:55:32 2019 GMT
*  issuer: CN=Fake LE Intermediate X1
*  SSL certificate verify result: unable to get local issuer certificate (20), continuing anyway.
...
```

## Open website in browser

Even if the website is not secure, can you link on advance link to continue to the website?

If Chrome complains something about HSTS, you config to disable k8 ingress to send HSTS header [like in this issue](https://github.com/kubernetes/ingress-nginx/issues/549).

## If everything looks good so far...

You can consider switch to letsencrypt's prod api call. Then start over the inspection steps above.

## What else you can check on?

In case you don't find anything useful after inspecting at resources above, you can try things below before using the last method - flushing everything and start over.

### Check out issuer

`bash ./my-kubectl.sh describe clusterissuer letsencrypt-staging`

### Check out the order

If the failure reason has something to do with order, look into order resources:

`. ./my-kubectl.sh get order --all-namespaces`

Particularly, look at if any failure or error present; if so, look at the reason.

- If you see reason is `Error finalizing order :: certificate public key must be different than account key`, check if `ClusterIssuer.spec.privateKeySecretRef` and `IngressResource.spec.tls.secretName` are not the same.

### Debug the ingress resources

- Get all the ingresses resources

`bash ./my-kubectl.sh get ingress -n cicd-django`

- Get the ingress resources description for django

`bash ./my-kubectl.sh get ingress project-shaungc-digitalocean-ingress-resource -n cicd-django -o yaml`

Does the annotation look right?

Because an issue [about get and describe](https://github.com/kubernetes/kubectl/issues/675#issuecomment-509686523), you might not be able to use `describe ingress <ingress namw>`, even you sepcify the correct namespace, will still get `Error from server (NotFound): ingresses.extensions <ingress name> not found`.

- Dump the aggregated `nginx.conf`

[Based on the k8 nginx](https://kubernetes.github.io/ingress-nginx/troubleshooting/).
1. Get the pod of the nginx controller first
1.  `kubectl exec -it -n <namespace-of-ingress-controller> <name of the pod> cat /etc/nginx/nginx.conf` 

## If something still don't go well - Flush everything and start over, if you feel this is necessary

Before doing this, try to read from logs above to find out what cause the error.

- ⚡ ~~To flush out all the cert, just run ⚡️ `. ./flush_cert_resources.sh`, specify LETSENCRYPT_ENV if needed (`staging` by default).~~

    1. ⚡️ This may be the most useful after you made changes to tf: **`terraform destroy -target=helm_release.project_cert_manager -target=helm_release.project-nginx-ingress`**

        - The above should already delete the custom resources together, but just to make sure you can run these command to verify that they are deleted: `bash ./my-kubectl.sh delete certificate letsencrypt-staging-secret && bash ./my-kubectl.sh delete clusterissuer letsencrypt-staging-issuer`
    1. You may also need to delete secrets created by cert-manager. List `bash ./my-kubectl.sh get secrets -n cert-manager`, then delete like ⚡️ `bash ./my-kubectl.sh delete secrets letsencrypt-staging-secret  -n cert-manager`.
    1. `terraform apply`.


