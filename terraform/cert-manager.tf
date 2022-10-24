
# based on
# https://blog.getambassador.io/using-jetstacks-kubernetes-cert-manager-to-automatically-renew-tls-certificates-in-the-ambassador-7db119ab34a4
resource "kubernetes_secret" "tls_route53_secret" {
  metadata {
    name      = "project-tls-cert-dns01-challenge-route53-credentials-secret"
    namespace = kubernetes_namespace.cert_manager.metadata.0.name
  }
  # k8 doc: https://github.com/kubernetes/community/blob/c7151dd8dd7e487e96e5ce34c6a416bb3b037609/contributors/design-proposals/auth/secrets.md#secret-api-resource
  # default type is opaque, which represents arbitrary user-owned data.
  type = "Opaque"

  data = {
    "secret-access-key" = var.aws_secret_key
  }
}


# cert-manager
#
#

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

locals {
  jetstack_cert_crd_version = "release-0.10"

  cert_cluster_issuer_name           = "letsencrypt-${var.letsencrypt_env}"

  cert_cluster_issuer_k8_secret_name = "${var.letsencrypt_env == "prod" ? local.cert_cluster_issuer_secret_name_prod : local.cert_cluster_issuer_secret_name_staging}"

  # cert-manager will look for ing w/ annotation `cluster-issuer`, and use that cluster issuer to create a certificate for the ing you are using this secret name in.
  # this should be used in `ing.spec.tls.secretName`.
  # the certificate data will be stored in this secret.
  # this secret, and the certificate created will be in the same namespace as the ingress.
  # since we are using wildcard and cluster issuer, we will only need one central TLS ing to generate certificate to cover all domains used in all microservices.
  central_tls_ing_certificate_secret_name = "wilcard-tls-ing-certificate-secret"

  # constant values
  cert_cluster_issuer_secret_name_prod = "letsencrypt-prod-secret"
  cert_cluster_issuer_secret_name_staging = "letsencrypt-staging-secret"
  acme_server_url_prod    = "https://acme-v02.api.letsencrypt.org/directory"
  acme_server_url_staging = "https://acme-staging-v02.api.letsencrypt.org/directory"
}


resource "null_resource" "crd_cert_resources_install" {
  triggers = {

    # list all dependencies here

    cluster_dependency = local_sensitive_file.kubeconfig.filename

    # only for creation (no effect for update)
    helm_cert_manager_dependency = helm_release.project_cert_manager.name

    cert_manager_namespace = kubernetes_namespace.cert_manager.metadata.0.name

    jetstack_cert_crd_version = local.jetstack_cert_crd_version

    cert_cluster_issuer_name  = local.cert_cluster_issuer_name
    cert_cluster_issuer_k8_secret_name = local.cert_cluster_issuer_k8_secret_name
    central_tls_ing_certificate_secret_name = local.central_tls_ing_certificate_secret_name

    letsencrypt_env         = var.letsencrypt_env
    acme_server_url_prod    = local.acme_server_url_prod
    acme_server_url_staging = local.acme_server_url_staging

    tls_route53_secret_name      = kubernetes_secret.tls_route53_secret.metadata.0.name
    tls_cert_covered_domain_list = join(";", local.tls_cert_covered_domain_list)

    aws_region                   = var.aws_region
    aws_access_key               = var.aws_access_key
    docker_email = var.docker_email
  }

  # (Issuer) Creation-Time Provisioners
  provisioner "local-exec" {
    command = <<EOT
echo INFO: creating issuer after 60 seconds ... && sleep 60 && cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ${local.cert_cluster_issuer_name}

spec:
  acme:
    server: ${var.letsencrypt_env == "prod" ? local.acme_server_url_prod : local.acme_server_url_staging}
    email: ${var.docker_email}
    privateKeySecretRef:
      name: ${local.cert_cluster_issuer_k8_secret_name}
    # dns01:
    #     providers:
    #     - name: route53
    #       route53:
    #         region: ${var.aws_region}
    #         accessKeyID: ${var.aws_access_key}
    #         secretAccessKeySecretRef:
    #             name: ${kubernetes_secret.tls_route53_secret.metadata.0.name}
    #             key: secret-access-key
    solvers:
    - selector:
        dnsZones:
        - "shaungc.com"
        # matchLabels:
        #   use-route53-solver: "true"
      dns01:
        route53:
          region: ${var.aws_region}
          accessKeyID: ${var.aws_access_key}
          secretAccessKeySecretRef:
            name: ${kubernetes_secret.tls_route53_secret.metadata.0.name}
            key: secret-access-key

EOF
EOT
  }

  # (Sleep)
  provisioner "local-exec" {
    command = "echo INFO: complete installing CRD and clusterissuer, will sleep 15 sec... && sleep 15"
  }

  # (Issuer Cert Secret)
  # TODO: deprecated for "destroy" provisioner referencing external resources / variables
  # we can follow the post below to correct the logic
  # https://discuss.hashicorp.com/t/how-to-rewrite-null-resource-with-local-exec-provisioner-when-destroy-to-prepare-for-deprecation-after-0-12-8/4580/2
  provisioner "local-exec" {
    # destroy provisioner will not run upon tainted (which is, update, or a re-create / replace is needed)
    when    = destroy
    command = self.triggers.letsencrypt_env == "prod" ? "echo && echo && echo INFO: will not delete secret for production letsencrypt due to quota concern. Please manually delete secret using kubectl if necessary." : join("\n", [
        # delete cluster issuer private key secret (generated by cert-manager), for letsencrypt api call, can differ for prod or staging.
        # no need to delete if you didn't make any change to ClusterIssuer.spec.acme
        # "kubectl delete secrets ${local.cert_cluster_issuer_secret_name_prod} ${local.cert_cluster_issuer_secret_name_staging} -n ${kubernetes_namespace.cert_manager.metadata.0.name}",

        # delete ing tls certificate secret (retrieved from letsencrypt api)
        # also as our deployment gets stable, we'll not delete the secret and rather reuse it,
        # so we can avoid exceeding the letsencrypt api limit
        # to have an idea how many requests you sent to letsencrypt production,
        # see https://crt.sh/?q=*.shaungc.com
        "kubectl delete secrets ${self.triggers.central_tls_ing_certificate_secret_name} -n ${self.triggers.cert_manager_namespace}",

        # delete ing tls certificate secret when using a centralized namespace
        # the content of certificate will be stored in this secret
        # but be careful when deleting prod secret
        "kubectl delete secrets ${self.triggers.cert_cluster_issuer_secret_name_prod} ${self.triggers.cert_cluster_issuer_secret_name_staging} -n ${self.triggers.cert_manager_namespace}",

        "echo",
        "echo",
        "echo INFO: delete certificate secrets complete, will sleep for 5 sec...",
        "sleep 5"
    ])
  }
}


resource "helm_release" "project_cert_manager" {
  name = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart = "cert-manager"
  version = "v1.7.3"

  namespace = kubernetes_namespace.cert_manager.metadata.0.name
  timeout   = "600"

  # Lets Kubernetes enough time to recognize the CRD and start up cert-managers validating webhook
  # Based on
  # https://github.com/hashicorp/terraform-provider-kubernetes-alpha/issues/72#issuecomment-802852500
  wait = true

  # ingressShim is used together with the ingress rule annotation `kubernetes.io/tls-acme: "true"`
  # it is for automated TLS certificate renewal
  # the doc also mentioned it is installed by default
  # but since we are doing dns01 challenge additionally,
  # we explictly specified `defaultIssuerName` and `defaultIssuerKind` as well, but
  # note that this might not be necessary.
  # https://docs.cert-manager.io/en/release-0.10/tasks/issuing-certificates/ingress-shim.html#configuration
  values = [<<EOF
    ingressShim:
      defaultIssuerName: ${local.cert_cluster_issuer_name}
      defaultIssuerKind: ClusterIssuer
      defaultACMEChallengeType: dns01
      defaultACMEDNS01ChallengeProvider: route53

      # Based on
      # https://cert-manager.io/docs/usage/ingress/#optional-configuration
      defaultIssuerGroup: cert-manager.io
  EOF
  ]

  set {
    name = "installCRDs"
    value = "true"
  }


  depends_on = [
    kubernetes_cluster_role_binding.tiller,
    kubernetes_service_account.tiller,

    # Based on cert-manager doc, creation ordering should be
    # install cert-manager -> install issuer -> configure ingress, etc
    # helm_release.project-nginx-ingress,
  ]
}
