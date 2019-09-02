# Debug and troubleshooting TLS

- Look at nginx logging, in realtime

`bash ./my-kubectl.sh logs --follow ds/nginx-ingress-controller -n kube-system`

- Look at cert manager logging, in realtime

`bash ./my-kubectl.sh logs --follow  $(bash ./my-kubectl.sh get pods -n cert-manager | grep cert-manager --max-count=1 | awk '{print $1}') -n cert-manager`

Does cert manager started working on certificate? It should generate a lot of log more than 15 lines.


- Check out certificate

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

- Check out the secrets for letsencrypt, and secrets for ingress tls

`. ./my-kubectl.sh get secrets --all-namespaces`

- Check out issuer

`bash ./my-kubectl.sh describe clusterissuer letsencrypt-staging`

- Hit the website

`curl -vkI https://shaungc.com`

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

- Open website in browser

Even if the website is not secure, can you link on advance link to continue to the website?

- ⚡To flush out all the cert, just run ⚡️ `. ./flush_cert_resources.sh`, specify LETSENCRYPT_ENV if needed (`staging` by default).

    1. ⚡️ `terraform destroy -target=helm_release.project_cert_manager -target=helm_release.project-nginx-ingress -target=kubernetes_secret.tls_route53_secret`

        - The above should already delete the custom resources together, but just to make sure you can run these command to verify that they are deleted: `bash ./my-kubectl.sh delete certificate letsencrypt-staging-secret && bash ./my-kubectl.sh delete clusterissuer letsencrypt-staging-issuer`
    1. You may also need to delete secrets created by cert-manager. List `bash ./my-kubectl.sh get secrets -n cert-manager`, then delete like ⚡️ `bash ./my-kubectl.sh delete secrets letsencrypt-staging-secret  -n cert-manager`.
    1. `terraform apply`.


# Debug ingress

- Get all the ingresses resources

`bash ./my-kubectl.sh get ingress -n cicd-django`

- Get the ingress resources description for django

`bash ./my-kubectl.sh get ingress project-shaungc-digitalocean-ingress-resource -n cicd-django -o yaml`

Does the annotation look right?

Because an issue [about get and describe](https://github.com/kubernetes/kubectl/issues/675#issuecomment-509686523), you might not be able to use `describe ingress <ingress namw>`, even you sepcify the correct namespace, will still get `Error from server (NotFound): ingresses.extensions <ingress name> not found`.