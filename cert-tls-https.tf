
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

  depends_on = [
    #   "null_resource.certmanager_namespace_config"
  ]
}


locals {
  jetstack_cert_crd_version = "release-0.9"

  cert_cluster_issuer_name           = "letsencrypt-${var.letsencrypt_env}"
  cert_cluster_issuer_k8_secret_name = "letsencrypt-${var.letsencrypt_env}-secret"

  acme_server_url_prod    = "https://acme-v02.api.letsencrypt.org/directory"
  acme_server_url_staging = "https://acme-staging-v02.api.letsencrypt.org/directory"
}



resource "null_resource" "crd_cert_resources_install" {
  triggers = {
      # change this string whenever you want to rerun the provisioners
      string_value = "const_value"
      always_trigger = "${timestamp()}"
  }


      # Terraform provisioners: https://www.terraform.io/docs/provisioners/index.html
  # (CRD) Creation-Time Provisioners
  provisioner "local-exec" {
    command = "echo INFO: installing CRD... && bash ./my-kubectl.sh apply -f https://raw.githubusercontent.com/jetstack/cert-manager/${local.jetstack_cert_crd_version}/deploy/manifests/00-crds.yaml && echo INFO: complete CRD installation, sleeping 10 sec... && sleep 10"
  }
  

  # (Issuer) Creation-Time Provisioners
  provisioner "local-exec" {
    command = <<EOT
echo INFO: creating issuer... && cat <<EOF | bash ./my-kubectl.sh apply -f -
apiVersion: certmanager.k8s.io/v1alpha1
kind: ClusterIssuer
metadata:
  name: ${local.cert_cluster_issuer_name}
#   namespace: ${kubernetes_namespace.cert_manager.metadata.0.name}
spec:
  acme:
    server: ${ var.letsencrypt_env == "prod" ? local.acme_server_url_prod : local.acme_server_url_staging }
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
  version = "v0.9.1"



  #   namespace = "${kubernetes_service_account.tiller.metadata.0.namespace}"
  namespace = "${kubernetes_namespace.cert_manager.metadata.0.name}"
    timeout   = "540"



  # var: TODO
  # description = "Let's Encrypt server URL to which certificate requests will be sent"
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



  # (CRD) Destroy-Time Provisioners
  provisioner "local-exec" {
    when    = "destroy"
    command = "bash ./my-kubectl.sh delete customresourcedefinitions.apiextensions.k8s.io certificates.certmanager.k8s.io clusterissuers.certmanager.k8s.io issuers.certmanager.k8s.io orders.certmanager.k8s.io && sleep 10"
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
