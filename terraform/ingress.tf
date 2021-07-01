locals {
  tls_cert_covered_domain_list = [
    "*.${var.managed_k8_rx_domain}",

    # no need to create for `api.` since the `*.api.` one already covers that; otherwisw cert-manager will throw error
    # "api.${var.managed_k8_rx_domain}",

    "*.api.${var.managed_k8_rx_domain}",

    "*.${random_uuid.random_domain.result}.${var.managed_k8_rx_domain}"
  ]
}

# code based: https://medium.com/@stepanvrany/terraforming-dok8s-helm-and-traefik-included-7ac42b5543dc
# Terraform official: helm_release - an instance of a chart running in a Kubernetes cluster. A Chart is a Helm package
# https://www.terraform.io/docs/providers/helm/release.html
# `helm_release` is similar to `helm install ...`
resource "helm_release" "project-nginx-ingress" {
  name      = "nginx-ingress-controller"
  namespace = kubernetes_service_account.tiller.metadata.0.namespace

  # this will delete & re-create this controller when config changed
  # note that this will let your service temporarily down as the controller pod IP will change
  # and will take some time for external dns to propogate the IP update
  # since we've already set updateStrategy.type to RollingUpdate, we're not likely needing this
  # unless you don't see the changed config reflected and you want to debug
  force_update = false

  # or chart = "stable/nginx-ingress"
  # see https://github.com/digitalocean/digitalocean-cloud-controller-manager/issues/162

  repository = "https://charts.helm.sh/stable"
  chart      = "nginx-ingress"
  # version = ""

  # available `set` specs: https://github.com/helm/charts/tree/master/stable/nginx-ingress

  # `set` below refer to SO answer
  # https://stackoverflow.com/a/55968709/9814131

  set {
    name  = "controller.kind"
    value = "DaemonSet"
  }

  set {
    name  = "controller.hostNetwork"
    value = true
  }

  set {
    name  = "controller.dnsPolicy"
    value = "ClusterFirstWithHostNet"
  }

  set {
    name  = "controller.daemonset.useHostPort"
    value = true
  }

  set {
    name  = "controller.service.type"
    value = "ClusterIP"
  }

  set {
    name  = "rbac.create"
    value = true
  }

  # exposing tcp services (non-http services, non-web server)
  # helm's way: https://github.com/helm/charts/issues/5408#issuecomment-388843681
  # nginx-ingress doc supporting tcp load balancing: https://kubernetes.github.io/ingress-nginx/user-guide/exposing-tcp-udp-services/
  #
  # steps required to expost a tcp port:
  # 1. specify the tcp port here and service it should point to
  # 2. allow the port in `digitalocean_firewall`

  # use api.shaungc.com:6378 on local to initiate connection
  set {
    name = "tcp.6378"
    value = "redis-cluster/redis-cluster-service:6379"
  }

  # use api.shaungc.com:5433 on local to initiate connection
  set {
    name = "tcp.5433"
    value = "postgres-cluster/postgres-cluster-service:5432"
  }

  # helm config for default certificate
  # https://github.com/helm/charts/blob/master/stable/nginx-ingress/values.yaml#L108
  set {
    name  = "controller.extraArgs.default-ssl-certificate"
    value = "${kubernetes_namespace.cert_manager.metadata.0.name}/${local.central_tls_ing_certificate_secret_name}"
  }

  values = [<<-EOF
    controller:
        # global nginx settings for all ingress rules
        config:
            # If a TLS block is present in ingress rule, the controller WILL redirect to TLS by default
            # However, it may not work for some reason; recommended to config this up in each service app
            ssl-redirect: "false"

            # never use this
            # redirecting to https even if there is no TLS block in your ingress
            # force-ssl-redirect: "false"

            # hsts config
            hsts: "true"
            hsts-include-subdomains: "true"
            hsts-max-age: "0"
            hsts-preload: "false"

            # set the upload file size limit
            # k8 nginx ingress doc: https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#proxy-body-size
            proxy-body-size: "1m" # default is 1m

            location-snippet: |
                # add custom nginx config here for location block
  EOF
  ]

  # in order to let terraform reflect update of this nginx controller, have to set to RollingUpdate; otherwise changes in tf won't take effect on k8
  # see https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/#updating-a-daemonset
  set {
    name  = "updateStrategy.type"
    value = "RollingUpdate"
  }

  # nginx debugging: https://github.com/kubernetes/ingress-nginx/blob/master/docs/troubleshooting.md#debug-logging
  set {
    name  = "controller.extraArgs.v"
    value = "4"
  }

  depends_on = [
    kubernetes_cluster_role_binding.tiller,
    kubernetes_service_account.tiller,

    null_resource.crd_cert_resources_install
  ]
}


# based on SO answer: https://stackoverflow.com/a/55968709/9814131
# format for `set` refer to official repo README: https://github.com/helm/charts/tree/master/stable/external-dns
resource "helm_release" "project-external-dns" {
  name      = "external-dns"
  repository = "https://charts.helm.sh/stable"
  chart     = "stable/external-dns"
  namespace = kubernetes_service_account.tiller.metadata.0.namespace

  # see available version by `. ./my-helm.sh search -l stable/external-dns`
  # app version refer to: https://github.com/kubernetes-sigs/external-dns/blob/master/CHANGELOG.md
  #
  # currenlty latest is not working, but app version 0.5.16 is confirm working so locking down here
  # https://github.com/kubernetes-sigs/external-dns/issues/1262#issuecomment-551912180
  # version = "v2.6.1"

  force_update = true

  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "aws.credentials.accessKey"
    value = var.aws_access_key
  }

  set {
    name  = "aws.credentials.secretKey"
    value = var.aws_secret_key
  }

  set {
    name  = "aws.region"
    value = var.aws_region
  }

  # domains you want external-dns to be able to edit
  # see terraform official blog: https://www.hashicorp.com/blog/using-the-kubernetes-and-helm-providers-with-terraform-0-12
  set {
    name  = "domainFilters[0]"
    value = var.managed_k8_rx_domain
  }

  #   set {
  #     name  = "registry"
  #     value = "txt"
  #   }
  #     set {
  #       name  = "txt-owner-id"
  #       value = "google-site-verification=E0yvL3DSuVCidTSdHUHMQWONt1iZYWXVqCVRkn4gQTQ"
  #     }

  set {
    name  = "policy"
    value = "sync" # "sync" | "upsert-only" (default): will disable deletion
  }

  set {
    name  = "rbac.create"
    value = true
  }

  depends_on = [
    kubernetes_cluster_role_binding.tiller,
    kubernetes_service_account.tiller
  ]
}


# template copied from terraform official doc: https://www.terraform.io/docs/providers/kubernetes/r/ingress.html
# modified based on SO answer: https://stackoverflow.com/a/55968709/9814131
resource "kubernetes_ingress" "project-ingress-resource" {
  metadata {
    name      = "tls-wildcard-cert-ingress-resource"
    namespace = kubernetes_namespace.cert_manager.metadata.0.name

    # annotation spec: https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/nginx-configuration/annotations.md#annotations
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"

      # we are already setting most of these configs in nginx controller

      # let the host below be interpreted as regex
      # "nginx.ingress.kubernetes.io/use-regex" = "true"

      # this is used together with ingressShim in ingress controller
      # https://docs.cert-manager.io/en/release-0.10/tasks/issuing-certificates/ingress-shim.html#configuration
      "kubernetes.io/tls-acme" = "true"

      # if want to share single TLS certificate, then only one ing should contain this annotation
      # https://github.com/jetstack/cert-manager/issues/841#issuecomment-414299467
      "certmanager.k8s.io/cluster-issuer" = local.cert_cluster_issuer_name
    }
  }

  spec {

    # do not put this same tls block in other ingress resources spec
    # if you want to share the tls domain, just place tls in one of the ingress resource
    # see https://github.com/jetstack/cert-manager/issues/841#issuecomment-414299467
    # `placing a host in the TLS config will indicate a cert should be created`
    # see https://github.com/jetstack/cert-manager/blob/master/docs/tasks/issuing-certificates/ingress-shim.rst#how-it-works
    tls {
      hosts = local.tls_cert_covered_domain_list

      # this will be used for default-ssl-certificate
      # this is the secret containing letsencrypt secrets,
      # not the one created by cert-manager
      # also not the certificate type resource
      secret_name = local.central_tls_ing_certificate_secret_name
    }
    # for registering wildcard tls certificate
    # see https://github.com/kubernetes/ingress-nginx/issues/4206#issuecomment-503140848
    #
    dynamic "rule" {
      for_each = local.tls_cert_covered_domain_list
      content {
        host = rule.value
        http {
          path {
            # this is just a place holder
            # the purpose of this ingress rule is to create
            # the single (wildcard) certificate shared by the whole cluster
            # for actual routes and service backends,
            # they should be created by each microservice
            # preferrably in their namespaces
            backend {}
            path = "/"
          }
        }
      }
    }
  }

  depends_on = [
    # do not run cert-manager before creating this ingress resource
    # ingress resource must be created first
    # see "4. Create ingress with tls-acme annotation and tls spec":
    # https://medium.com/asl19-developers/use-lets-encrypt-cert-manager-and-external-dns-to-publish-your-kubernetes-apps-to-your-website-ff31e4e3badf
    # DON't ->

    # above may not be true - see https://github.com/jetstack/cert-manager/blob/master/docs/tutorials/acme/quick-start/index.rst#step-7---deploy-a-tls-ingress-resource
    helm_release.project_cert_manager,
  ]
}

