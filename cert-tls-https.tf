
# based on
# https://blog.getambassador.io/using-jetstacks-kubernetes-cert-manager-to-automatically-renew-tls-certificates-in-the-ambassador-7db119ab34a4
# for adding dns challenge support for wildcard domain tls protection
# resource "helm_release" "project_ambassador" {
#     name = "project_ambassador_for_tls"

#     chart = "stable/ambassador"
#     version = "1.1.0"
# }

resource "kubernetes_secret" "tls_route53_secret" {
  metadata {
    name      = "project-tls-cert-dns01-challenge-route53-credentials-secret"
    namespace = "${kubernetes_namespace.cert_manager.metadata.0.name}"
  }
  # k8 doc: https://github.com/kubernetes/community/blob/c7151dd8dd7e487e96e5ce34c6a416bb3b037609/contributors/design-proposals/auth/secrets.md#secret-api-resource
  # default type is opaque, which represents arbitrary user-owned data.
  type = "Opaque"

  data = {
    "secret-access-key" = "${var.aws_secret_key}"
  }
}







# cert-manager
#
#
#

data "helm_repository" "jetstack" {
  name = "jetstack"
  url  = "https://charts.jetstack.io"
}

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"

    labels = {
      "certmanager.k8s.io/disable-validation" = "true"
    }
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
    #
    #
    jetstack_cert_crd_version = "${local.jetstack_cert_crd_version}"
    cert_cluster_issuer_name  = "${local.cert_cluster_issuer_name}"

    letsencrypt_env         = "${var.letsencrypt_env}"
    acme_server_url_prod    = "${local.acme_server_url_prod}"
    acme_server_url_staging = "${local.acme_server_url_staging}"

    docker_email = "${var.docker_email}"

    cert_cluster_issuer_k8_secret_name = "${local.cert_cluster_issuer_k8_secret_name}"

    aws_region                   = "${var.aws_region}"
    aws_access_key               = "${var.aws_access_key}"
    tls_route53_secret_name      = "${kubernetes_secret.tls_route53_secret.metadata.0.name}"
    tls_cert_covered_domain_list = "${join(";", local.tls_cert_covered_domain_list)}"

    # ingress controller
    # ingress_controller = "${helm_release.project-nginx-ingress.metadata.0.values}"
    # ingress_controller_revision = "${helm_release.project-nginx-ingress.metadata.0.revision}"
  }


  # Terraform provisioners: https://www.terraform.io/docs/provisioners/index.html
  # (CRD) Creation-Time Provisioners
  provisioner "local-exec" {
    command = "echo INFO: installing CRD... && sleep 5 && bash ./my-kubectl.sh apply -f https://raw.githubusercontent.com/jetstack/cert-manager/${local.jetstack_cert_crd_version}/deploy/manifests/00-crds.yaml && echo INFO: complete CRD installation, sleeping 10 sec... && sleep 10"
  }


  # (Issuer) Creation-Time Provisioners
  provisioner "local-exec" {
    command = <<EOT
echo INFO: creating issuer... && cat <<EOF | bash ./my-kubectl.sh apply -f -
apiVersion: certmanager.k8s.io/v1alpha1
kind: ClusterIssuer
metadata:
  name: ${local.cert_cluster_issuer_name}

spec:
  acme:
    server: ${var.letsencrypt_env == "prod" ? local.acme_server_url_prod : local.acme_server_url_staging}
    email: ${var.docker_email}
    privateKeySecretRef:
      name: ${local.cert_cluster_issuer_k8_secret_name}
    dns01:
        providers:
        - name: route53
          route53:
            region: ${var.aws_region}
            accessKeyID: ${var.aws_access_key}
            secretAccessKeySecretRef:
                name: ${kubernetes_secret.tls_route53_secret.metadata.0.name}
                key: secret-access-key
    solvers:
    - dns01:
        selector:
          matchLabels:
            use-route53-solver: "true"
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
  # other kinds of challenge:
  #   solvers:
  #   - http01:
  #     ingress:
  #       class: nginx

  # http01: {}
  #
  #   dns01:
  #         providers:
  #           - name: route53
  #             route53:
  #                 region: ${var.aws_region}
  #                 accessKeyID: ${var.aws_access_key}
  #                 secretAccessKeySecretRef:
  #                     name: ${kubernetes_secret.tls_route53_secret.metadata.0.name}
  #                     key: secret-access-key
  # https://blog.getambassador.io/using-jetstacks-kubernetes-cert-manager-to-automatically-renew-tls-certificates-in-the-ambassador-7db119ab34a4

  # solver based on 
  # https://github.com/cloud-ark/kubeplus/blob/master/examples/cert-management/working-config/issuer.yaml referred from https://github.com/jetstack/cert-manager/issues/1148#issuecomment-499236255


  # (CRD) Destroy-Time Provisioners
  provisioner "local-exec" {
    when    = "destroy"
    # command = "bash ./my-kubectl.sh delete customresourcedefinitions.apiextensions.k8s.io certificates.certmanager.k8s.io clusterissuers.certmanager.k8s.io issuers.certmanager.k8s.io orders.certmanager.k8s.io certificaterequests.certmanager.k8s.io challenges.certmanager.k8s.io \n echo \n echo \n echo \n echo INFO: delete certificate resources complete, will sleep for 10 sec... \n sleep 10"

    # based on jetstack/cert-manager doc: 
    # http://docs.cert-manager.io/en/latest/tasks/upgrading/upgrading-0.5-0.6.html#upgrading-from-older-versions-using-helm
    command = "bash ./my-kubectl.sh delete crd certificates.certmanager.k8s.io clusterissuers.certmanager.k8s.io issuers.certmanager.k8s.io \n echo \n echo \n echo \n echo INFO: delete certificate resources complete, will sleep for 10 sec... \n sleep 10"
  }
  # delete 
  # customresourcedefinitions.apiextensions.k8s.io 
  # > certificates.certmanager.k8s.io 
  # > clusterissuers.certmanager.k8s.io 
  # > issuers.certmanager.k8s.io 
  # orders.certmanager.k8s.io 
  # certificaterequests.certmanager.k8s.io 
  # challenges.certmanager.k8s.io

  # (Issuer Cert Secret)
  provisioner "local-exec" {
    when    = "destroy"
    command = "${join("\n", [
        # delete cluster issuer private key secret, for letsencrypt api call, can differ for prod or staging.
        # no need to delete if you didn't make any change to ClusterIssuer.spec.acme
        # "bash ./my-kubectl.sh delete secrets ${local.cert_cluster_issuer_secret_name_prod} ${local.cert_cluster_issuer_secret_name_staging} -n ${kubernetes_namespace.cert_manager.metadata.0.name}",

        # delete ing tls certificate secret (if the ing is in cert-manager namespace. If ing is in microservices' own namespace, this command is useless)
        # # also as our deployment gets stable, we'll not delete the secret and rather reuse it,
        # so we can avoid exceeding the letsencrypt api limit
        # to have an idea how many requests you sent to letsencrypt production,
        # see https://crt.sh/?q=*.shaungc.com
        # "bash ./my-kubectl.sh delete secrets ${local.central_tls_ing_certificate_secret_name} -n ${kubernetes_namespace.cert_manager.metadata.0.name}",

        # delete ing tls certificate secret in each microservice namespace, if microservices are deployed in their own namespace (hence having their own certificates in their namespaces)
        #
        # "bash ./my-kubectl.sh delete secrets ${local.cert_cluster_issuer_secret_name_prod} ${local.cert_cluster_issuer_secret_name_staging} -n ${module.iriversland2_api.microservice_namespace}",
        # "bash ./my-kubectl.sh delete secrets ${local.cert_cluster_issuer_secret_name_prod} ${local.cert_cluster_issuer_secret_name_staging} -n ${module.appl_tracky_api.microservice_namespace}",

        "echo",
        "echo",
        "echo INFO: delete certificate secrets complete, will sleep for 5 sec...",
        "sleep 5"
    ])}"
  }
}



# resource "null_resource" "certcrdinstall" {
#   provisioner "local-exec" {
#     command = "bash ./my-kubectl.sh apply -f https://raw.githubusercontent.com/jetstack/cert-manager/${local.jetstack_cert_crd_version}/deploy/manifests/00-crds.yaml && sleep 30"
#   }
# }

# resource "null_resource" "certcrddestroy" {
#   provisioner "local-exec" {
#       command = "bash ./my-kubectl.sh delete customresourcedefinitions.apiextensions.k8s.io certificates.certmanager.k8s.io clusterissuers.certmanager.k8s.io issuers.certmanager.k8s.io"
#   }
# }



resource "helm_release" "project_cert_manager" {

  name = "cert-manager"

  #   repository = "charts.jetstack.io"
  repository = "${data.helm_repository.jetstack.metadata.0.name}"

  #   chart = "stable/cert-manager"
  chart = "jetstack/cert-manager"



  // Since v0.6.0, cert-manager Helm chart doesn't provide
  // a good way of installing the cert-manager CRDs
  #   version = "v0.5.2"
#   version = "v0.9.1"
  version = "v0.10.0-alpha.0"



  #   namespace = "${kubernetes_service_account.tiller.metadata.0.namespace}"
  namespace = "${kubernetes_namespace.cert_manager.metadata.0.name}"
  timeout   = "540"
  
  # ingressShim 
  # cert-manager doc
  # https://github.com/jetstack/cert-manager/blob/master/docs/tasks/issuing-certificates/ingress-shim.rst#configuration
  values = [<<EOF
    ingressShim:
      defaultIssuerName: ${local.cert_cluster_issuer_name}
      defaultIssuerKind: ClusterIssuer
      defaultACMEChallengeType: dns01
      defaultACMEDNS01ChallengeProvider: route53
  EOF
  ]

  # diable webhook to avoid error using stable/cert-manager: https://github.com/jetstack/cert-manager/issues/1255#issuecomment-465129995
  set {
    name  = "webhook.enabled"
    value = "false"
  }



  depends_on = [
    "kubernetes_cluster_role_binding.tiller",
    "kubernetes_service_account.tiller",

    "helm_release.project-nginx-ingress",

    "null_resource.crd_cert_resources_install"
  ]
}




# resource "helm_release" "tls-cluster-issuer" {
#   name       = "cluster-issuer"
#   chart      = "..\\..\\Assets\\cluster-issuer" # TODO code is at https://github.com/MathieuBuisson/PSAksDeployment/tree/master/PSAksDeployment/Assets/cluster-issuer
#   depends_on = ["helm_release.project-cert-manager"]

#     # var
#     # # TODO: email
#   values = [<<EOF
#   email: ${var.letsencrypt_email_address} 
#   environment: ${var.letsencrypt_environment}
# EOF
#   ]
# }


# resource "null_resource" "create_cert_issuer" {
#   provisioner "local-exec" {
#     command = <<EOT
# cat <<EOF | bash ./my-kubectl.sh create -f -
# apiVersion: certmanager.k8s.io/v1alpha1
# kind: ClusterIssuer
# metadata:
#   name: ${local.cert_cluster_issuer_name}
# spec:
#   acme:
#     server: ${local.acme_server_url_staging}
#     email: ${var.docker_email}
#     privateKeySecretRef:
#       name: ${local.cert_cluster_issuer_k8_secret_name}
#     solvers:
#       - http01:
#         ingress:
#           class: nginx
# EOF
# EOT
#   }

#   depends_on = [
#     "helm_release.project_cert_manager"
#   ]
# }
