# Goal

- ✅ HSTS disable for development purpose
- ✅ Verify letsencrypt staging is working
- ✅ Move to letsencrypt prod
- Debug appl tracky app itself --> delegated to issue
- (Database backup for appl-tracky) --> delegated to issue
- (Think about CI/CD for appl-tacky) --> delegated to issue
- (Clean up code)
- (Documentation)


## Disable HSTS

- ✅ Delete browser hsts cache.
- ✅ Disable server hsts header.
    - ✅ After disable, dump nginx.conf to check.

Attempts to disable server hsts header
- Create a configmap resource w/ same name as ing controller's autogen configmap to overwrite - not working. Ing controller will gen another configmap `nginx-ingress-controller.v1`. When checking dumped nginx.conf, our configmap value does not show up there.
- Give a set entry in helm ing controller
    - TF w/o error ok
    - (Seems the `nginx-ingress-controller.v1` will always be generated! Even if we don't create any configmap and using `set` on helm_release)
    - Nothing related to hsts showing up in `nginx.conf`.
    - Adding more entry, and actually enable it - so that is more [likely to gen sth in `nginx.conf`](https://serverfault.com/questions/874936/adding-hsts-to-nginx-config).
    - 🎉 Bingo! Got strings `Strict-Transport-Security` in `nginx.conf` And this is an effective way to verify our configmap change is honored.

How to verify configmap change applied?
1. Get the pod of ingress controller.
1. Dump the `nginx.conf` by `. ./my-kubectl.sh exec -it -n kube-system nginx-ingress-controller-controller-6p5sz cat /etc/nginx/nginx.conf > nginx.conf`, where `nginx-ingress-controller-controller-6p5sz` is the pod name.
1. Search in the `nginx.conf` for keywords that related to your change in configmap.

## Move to letsencrypt prod

We'll go back to [the issue page](https://github.com/rivernews/appl-tracky-api/issues/6#issuecomment-526965026) to follow the debug process for prod.