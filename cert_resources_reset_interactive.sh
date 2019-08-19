LETSENCRYPT_ENV=${1:-staging}
DOMAIN_TO_CHECK=shaungc.com

# echo "INFO: Let's Encypt Environment:\n${LETSENCRYPT_ENV}\n\nEnter anything to continue."
# read

# echo "INFO: will now run terraform destroy and delete all tls secrets ..."

# terraform destroy -target=helm_release.project_cert_manager -target=helm_release.project-nginx-ingress -target=kubernetes_secret.tls_route53_secret -auto-approve


# bash ./my-kubectl.sh delete secrets letsencrypt-${LETSENCRYPT_ENV}-secret  -n cert-manager

# echo "\n\nINFO: reset done, will now terraform apply to re-create everything.\nEnter anything to continue."
# read

# terraform apply -var="letsencrypt_env=${LETSENCRYPT_ENV}" -auto-approve

# echo "terraform just finished provisioning, sleep for 10 sec..."  && sleep 10

# echo "\n\nINFO: cert-manager, letsencypt, issuer, certifcate config complete. Ready to verify.\nEnter anything to continue."
# read




# verify check based on https://github.com/bitnami/kube-prod-runtime/issues/532#issuecomment-491763784
#
#

bash ./my-kubectl.sh get ingress project-shaungc-digitalocean-ingress-resource -n cicd-django -o yaml
echo "\nINFO: check the ingress resource:"
echo "Is it using cluster issuer annotation?"
echo "Does the tls domain names seem right?"
echo "Enter anything to continue."
read



bash ./my-kubectl.sh describe clusterissuer letsencrypt-${LETSENCRYPT_ENV}
echo "\nINFO: check the cluster issuer:"
echo "Is it using environment ${LETSENCRYPT_ENV}?"
echo "Does the acme challenge config seem right?"
echo "Enter anything to continue."
read


bash ./my-kubectl.sh describe certificate letsencrypt-${LETSENCRYPT_ENV}-secret -n cicd-django
echo "\nINFO: check the certificate:"
echo "Is it using environment ${LETSENCRYPT_ENV}?"
echo "Is it created successfully?"
echo "Does the acme challenge seem right?"
echo "Enter anything to continue."
read



URL_TO_CHECK=https://${DOMAIN_TO_CHECK}/
curl -vkI ${URL_TO_CHECK}
echo "\nINFO: check the website https (curl):"
if [[ ${LETSENCRYPT_ENV} == "staging" ]]
then
    echo "Is the \"issuer\" something like \"CN=Fake LE Intermediate X1?\""
else
    echo "Is the \"issuer\" something like \"C=US; O=Let's Encrypt; CN=Let's Encrypt Authority X3?\" "
fi
echo "You can also open browser to check: ${URL_TO_CHECK}"
echo "INFO: if you don't see the right issuer, please be patient to wait for a while like 10 minutes and retry https request again, it might be still propagating certificates."
echo "Enter anything to continue."
read

echo "\n\n\nINFO: check successfully completed."
