locals {
  #   app_deployed_domain_hashed = "${var.app_container_image_tag}.${var.app_deployed_domain}"

  #   deployed_domain_list = [
  #     "${local.app_deployed_domain_hashed}",
  #     "${var.app_deployed_domain}",
  #   ]

  tls_cert_covered_domain_list = [
    "*.${var.managed_k8_rx_domain}",
    # no need to create for `api.` since the `*.api.` one already covers that and cert-manager will throw error
    # "api.${var.managed_k8_rx_domain}",
    "*.api.${var.managed_k8_rx_domain}"
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

  repository = data.helm_repository.stable.metadata.0.name
  chart      = "nginx-ingress"
  # version = ""

  # helm chart values (equivalent to yaml)
  # https://github.com/terraform-providers/terraform-provider-helm/issues/145



  # `set` below refer to SO answer
  # https://stackoverflow.com/a/55968709/9814131

  # `set` spec: https://github.com/helm/charts/tree/master/stable/nginx-ingress

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

  set {
    # nginx debugging: https://github.com/kubernetes/ingress-nginx/blob/master/docs/troubleshooting.md#debug-logging
    name  = "controller.extraArgs.v"
    value = "4"
  }

  # helm config for default certificate 
  # https://github.com/helm/charts/blob/master/stable/nginx-ingress/values.yaml#L108
  set_string {
    name  = "controller.extraArgs.default-ssl-certificate"
    # value = "${kubernetes_namespace.cert_manager.metadata.0.name}/${local.cert_cluster_issuer_k8_secret_name}"
    # because we use iriversland2-api as fallback service, so the secret will be created there
    # value = "${module.iriversland2_api.microservice_namespace}/${local.cert_cluster_issuer_k8_secret_name}"
    value = "${kubernetes_namespace.cert_manager.metadata.0.name}/${local.central_tls_ing_certificate_secret_name}"
  }


  # equivalent to the data section in a `configmap` resource
  # setting is global across all ing resources
  # avoiding bool parsing error in configmap
  # see https://github.com/helm/charts/issues/9586#issuecomment-461117432
  #   set_string {
  #     name  = "controller.config.ssl-redirect"
  #     value = "false"
  #   }
  #   set_string {
  #     name  = "controller.config.hsts"
  #     value = "true"
  #   }
  #   set_string {
  #     name  = "controller.config.hsts-include-subdomains"
  #     value = "true"
  #   }
  #   set_string {
  #     name  = "controller.config.hsts-max-age"
  #     value = "0"
  #   }
  #   set_string {
  #     name  = "controller.config.hsts-preload"
  #     value = "false"
  #   }


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
                # add custom nginx config here
  EOF
  ]



  #   set {
  #       name = "controller.configMapNamespace"
  #       # same as this ing controller
  #       value = "${kubernetes_service_account.tiller.metadata.0.namespace}"
  #   }

  #   set {
  #       name = "controller.extraArgs.configmap"
  #       value = "${kubernetes_config_map.ingress_controller_configmap.metadata.0.namespace}/${kubernetes_config_map.ingress_controller_configmap.metadata.0.name}"
  #   }

  # in order to let terraform reflect update of this nginx controller, have to set to RollingUpdate; otherwise changes in tf won't take effect on k8
  # see https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/#updating-a-daemonset
  set {
    name  = "updateStrategy.type"
    value = "RollingUpdate"
  }

  depends_on = [
    kubernetes_cluster_role_binding.tiller,
    kubernetes_service_account.tiller,

    null_resource.crd_cert_resources_install
  ]
}



# deprecated - use helm_release.project-nginx-ingress set_string "controller.config.<configmap entry here>" instead
# tf spec doc: https://www.terraform.io/docs/providers/kubernetes/r/config_map.html
# following SO: https://stackoverflow.com/a/54888611/9814131
# resource "kubernetes_config_map" "ingress_controller_configmap" {
#   metadata {
#     name = "${helm_release.project-nginx-ingress.name}-controller"
#     # name = "my-ing-controller-configmap"

#     # same as ing controller
#     # namespace = "${kubernetes_service_account.tiller.metadata.0.namespace}"
#     namespace = "${helm_release.project-nginx-ingress.namespace}"
#   }

#   # disable hsts
#   # refer to https://github.com/kubernetes/ingress-nginx/issues/549#issuecomment-294582915
#   # if you found your browser still cannot access the website after clicking advance, you should delete the cached hsts in your browser, for chrome go to chrome://net-internals/#hsts , for other browser,  see: https://www.thesslstore.com/blog/clear-hsts-settings-chrome-firefox/
#   data = {
#     hsts = "true"
#     "hsts-include-subdomains" = "true"
#     "hsts-max-age" = "0"
#     "hsts-preload" = "false"
#   }
# }





# based on SO answer: https://stackoverflow.com/a/55968709/9814131
# format for `set` refer to official repo README: https://github.com/helm/charts/tree/master/stable/external-dns
# data "aws_route53_zone" "selected" {
#   name         = "${var.managed_route53_zone_name}"
#   private_zone = false
# }
resource "helm_release" "project-external-dns" {
  name      = "external-dns"
  chart     = "stable/external-dns"
  namespace = kubernetes_service_account.tiller.metadata.0.namespace

  # see available version by `. ./my-helm.sh search -l stable/external-dns`
  # app version refer to: https://github.com/kubernetes-sigs/external-dns/blob/master/CHANGELOG.md
  #
  # currenlty latest is not working, but app version 0.5.16 is confirm working so locking down here
  # https://github.com/kubernetes-sigs/external-dns/issues/1262#issuecomment-551912180
  version = "v2.6.1"

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

      # annotation `tls-acme` seems useless, the `cluster-issuer` does the auto cert creation
      # do we need this? because of dns01 challenge?
      # see https://github.com/jetstack/cert-manager/blob/master/docs/tutorials/acme/quick-start/index.rst#step-7---deploy-a-tls-ingress-resource
      "kubernetes.io/tls-acme" = "true"

      # if want to share single TLS certificate, then only one ing should contain this annotation
      # https://github.com/jetstack/cert-manager/issues/841#issuecomment-414299467
      "certmanager.k8s.io/cluster-issuer" = local.cert_cluster_issuer_name
    }
  }

  spec {

    # do not put this same tls in other ingress resources spec
    # if you want to share the tls domain, just place tls in one of the ingress resource
    # see https://github.com/jetstack/cert-manager/issues/841#issuecomment-414299467
    # `placing a host in the TLS config will indicate a cert should be created`
    # see https://github.com/jetstack/cert-manager/blob/master/docs/tasks/issuing-certificates/ingress-shim.rst#how-it-works
    tls {
      # hosts       = ["${local.app_deployed_domain}", "${var.managed_k8_rx_domain}"]
      #   hosts = ["${var.managed_k8_rx_domain}", "*.${var.managed_k8_rx_domain}"]
      hosts = local.tls_cert_covered_domain_list
      #   hosts       = ["${var.managed_k8_rx_domain}", "${local.app_deployed_domain}", "*.${var.managed_k8_rx_domain}"]

      #   secret_name = "${local.cert_cluster_issuer_k8_secret_name}"
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
            backend {
              #   service_name = "${kubernetes_service.app.metadata.0.name}"
              service_name = module.iriversland2_api.microservice_kubernetes_service_name
              service_port = module.iriversland2_api.microservice_kubernetes_service_port
            }

            path = "/"
          }
        }
      }
    }

    # dynamic "rule" {
    #   for_each = local.deployed_domain_list
    #   content {
    #     host = rule.value
    #     http {
    #       path {
    #         backend {
    #           service_name = "${kubernetes_service.app.metadata.0.name}"
    #           service_port = "${var.app_exposed_port}"
    #         }

    #         path = "/"
    #       }
    #     }
    #   }
    # }

    // microservice rules

    # dynamic "rule" {
    #   for_each = local.microservices_ingress_resource_rules
    #   content {
    #     host = rule.value.microservice_deployed_domain
    #     http {
    #       path {
    #         backend {
    #           service_name = rule.value.microservice_kubernetes_service_name
    #           service_port = rule.value.microservice_kubernetes_service_port
    #         }

    #         path = "/"
    #       }
    #     }
    #   }
    # }

    # Add more ingest service here
    # ...

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

