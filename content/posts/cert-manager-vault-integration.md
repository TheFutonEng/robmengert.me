---
title: "Cert Manager Vault Integration"
date: 2023-08-05T08:33:43-06:00
draft: true
---

Introduction
============

I explored using Cert-Manager to configure ingress objects in Kubernetes with TLS certificates automatically, and this post documents some lessons learned. A root certificate authority (CA) already exists in my home lab environment outside of a K8s cluster, so I set up an in-cluster instance of [Hashicorp Vault](https://www.hashicorp.com/products/vault) to host an intermediate CA and integrate it with [Cert-Manager](https://cert-manager.io/).

Prerequisites
=============

In case you want to follow along, you will need the following:

*   A Kubernetes cluster (mine is K3s running on bare metal, but any distro should do)
*   Kubectl

Objectives
==========

*   Explore Cert-Manager
*   Explore Vault
*   Explore integration between the two projects
*   Use a cluster-issuer to place a cert on an Ingress endpoint

CA Details
==========

Some important details to know about the setup. The CA was stood up using [this guide](https://jamielinux.com/docs/openssl-certificate-authority/index.html) with one important tweak. The [openssl.cnf file](https://jamielinux.com/docs/openssl-certificate-authority/appendix/intermediate-configuration-file.html) used for the intermediate CA in that guide has the following section for v3   _intermediate_ca:

```bash
\[ v3_intermediate_ca \]  
\# Extensions for a typical intermediate CA (\`man x509v3_config\`).  
subjectKeyIdentifier = hash  
authorityKeyIdentifier = keyid:always,issuer  
basicConstraints = critical, CA:true, pathlen:0  
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
```

The important detail to be modified is on the `basicConstraints` line. The `pathlen:0` argument means that no further intermediate CA certs can be cut off of this certificate. However, that is exactly what Vault is going to be asked to do so while standing up the CA. The above snippet was changed to the following:

```bash
\[ v3_intermediate_ca \]  
\# Extensions for a typical intermediate CA (\`man x509v3_config\`).  
subjectKeyIdentifier = hash  
authorityKeyIdentifier = keyid:always,issuer  
basicConstraints = critical, CA:true  
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
```

The difference is that `pathlen:0`  was removed, thus allowing additional intermediates to be cut.

Some certificate/key details must be prepped at this stage. [Vault requires a CA bundle to be loaded into the PKI secrets engine](https://developer.hashicorp.com/vault/api-docs/secret/pki#import-ca-certificates-and-keys), which will be done via an API call.

The first thing to do for this prep is to modify the intermediate key. When following the previously linked guide to stand up a local CA, the root and intermediate keys are encrypted, which, you know, good. However, Vault isn’t going to be able to read the key in its current state. The following command snippet switches into the proper directory, decrypts the key, and outputs it to a file:

```bash
cd /root/ca/intermediate/private/  
openssl rsa -in intermediate.key.pem -out decrypted_key.pem
```

The bundle to be uploaded to Vault can now be prepped since the intermediate key has been decrypted. The intermediate cert, intermediate key, and root cert are required in the bundle, specifically in that order:

```bash
cd /root/ca  
cat intermediate/certs/intermediate.cert.pem \\  
intermediate/private/decrypted_key.pem certs/ca.cert.pem > vault_bundle.pem
```

Snippet from the [Vault docs](https://developer.hashicorp.com/vault/api-docs/secret/pki#import-ca-certificates-and-keys): “Note that if you provide the data through the HTTP API, it must be JSON-formatted, with newlines replaced with `\n`”

To that end, the pem bundle must be reformatted:

```bash
pem_bundle_value=$(awk '{printf "%s\\\\n", $0}' vault_bundle.pem)  
echo '{"pem_bundle": "'"${pem_bundle_value}"'"}' > vault_bundle.json
```

And now all of the local CA prep work is done. Before using any of these artifacts, Vault needs to be installed.

Vault Installation
==================

Vault was installed using Helm with some custom values in a values.yaml file.

```bash
kubectl create ns vault  
helm repo add hashicorp https://helm.releases.hashicorp.com  
helm upgrade -i vault hashicorp/vault --version 0.23.0 \\  
\-n vault -f values.yaml
```

Note, the namespace was created imperatively before the `helm` command was run.

Let’s take a look at the values.yaml file:

```yaml
ui:  
  enabled: true  
  serviceType: "LoadBalancer"  
  serviceNodePort: null  
  externalPort: 8200  
  loadBalancerIP: 192.168.1.242  
server:   
  extraEnvironmentVars:  
    VAULT_CACERT: /vault/userconfig/tls-ca/tls.crt  
    VAULT_ADDR: https://127.0.0.1:8200  
    VAULT_API_ADDR: https://$(POD_IP):8200  
  extraVolumes:  
    - type: secret  
      name: tls-ca  
    - type: secret  
      name: vault-ui-tls  
  standalone:  
    enabled: true   
    config: |  
      ui = true  
  
      listener "tcp" {  
        tls_disable = false  
        address     = "0.0.0.0:8200"  
        tls_cert_file = "/vault/userconfig/vault-ui-tls/tls.crt"  
        tls_key_file = "/vault/userconfig/vault-ui-tls/tls.key"  
        tls_client_ca_file = "/vault/userconfig/tls-ca/tls.crt"  
  
  
      }  
  
      storage "file" {  
        path = "/vault/data"  
      }  
  
  dataStorage:  
    enabled: true   
    storageClass: longhorn  
  auditStorage:  
    enabled: true  
    storageClass: longhorn
```

I’ll dig into this file but won’t provide any configuration. The `ui` section declares that the UI is enabled and is to be served on a service of type `loadBalancer` which [KubeVIP](https://kube-vip.io/) handles in this cluster.

The `extraVolumes` section mounts in the CA cert from the local CA and a cert/key pair for the Vault UI to use and to prevent TLS errors while interacting with Vault. These items are created in the cluster separately and imperatively via `kubectl` commands. This is an opportunity for improvement but is how things are running at the time of this writing.

The `standalone` section declares that Vault is not operating in HA mode. This is fine for a home lab where seven 9’s of availability is not required. This is not suitable for any type of production environment. The rest of this section defines a configuration file that Vault will use and instructs Vault where to find the CA cert and the cert/key pair to use on the UI.

The `dataStorage` and `auditStorage` sections enable persistent storage for Vault via [Longhorn](https://longhorn.io/).

Vault Configuration
===================

The above Helm command installs Vault as a statefulSet with a replica of 1 (recall, `standalone.enabled = true` from the values file). This replica will not show as `Ready` until further configuration is done within the pod, and that’s what this section will cover.

I elected to go with a configuration method where a script was created as part of a configMap and used in a [Kubernetes job](https://kubernetes.io/docs/concepts/workloads/controllers/job/). That posture means that some additional objects were required in the cluster:

```yaml
apiVersion: v1  
data:  
  ca-chain.cert.pem: <<OMITTED>>  
kind: Secret  
metadata:  
  name: ca-cert  
  namespace: vault  
\---  
apiVersion: v1  
kind: ServiceAccount  
metadata:  
  name: kubectl-vault  
  namespace: vault  
\---  
kind: Role  
apiVersion: rbac.authorization.k8s.io/v1  
metadata:  
  namespace: vault  
  name: pod-exec  
rules:  
\- apiGroups: \[""\]  
  resources: \["pods", "pods/log"\]  
  verbs: \["get", "list"\]  
\- apiGroups: \[""\]  
  resources: \["pods/exec"\]  
  verbs: \["create"\]  
\---  
apiVersion: rbac.authorization.k8s.io/v1  
kind: RoleBinding  
metadata:  
  name: kubectl  
  namespace: vault  
roleRef:  
  apiGroup: rbac.authorization.k8s.io  
  kind: Role  
  name: pod-exec  
subjects:  
\- namespace: vault  
  kind: ServiceAccount  
  name: kubectl-vault  
\---  
apiVersion: batch/v1  
kind: Job  
metadata:  
  namespace: vault  
  name: vault-configure  
spec:  
  template:  
    spec:  
      serviceAccountName: kubectl-vault  
      restartPolicy: Never  
      containers:  
      - image: thefutoneng/kubectl:0.3  
        name: vault-configure  
        command:   
        - /bin/sh  
        - /root/vault-config/vault_config.sh  
        volumeMounts:  
        - name: vault-data  
          mountPath: /root/vault-data  
        - name: vault-config-script  
          mountPath: /root/vault-config  
        - name: ca-cert  
          mountPath: /root/ca-cert  
      volumes:  
      - name: vault-config-script  
        configMap:  
          name: vault-config-script  
          defaultMode: 0755  
      - name: vault-data  
        hostPath:  
          path: /mnt/k8s/vault  
          type: Directory  
      - name: ca-cert  
        secret:  
          secretName: ca-cert  

```

The job in the above YAML file references a script called `vault_config.sh` mounted in from a configMap, which is used to bootstrap Vault. Here is that configMap:

```yaml
apiVersion: v1  
kind: ConfigMap  
metadata:  
  namespace: vault  
  name: vault-config-script  
data:  
  vault_config.sh: |-  
    #!/bin/sh  
  
    # Lots of the commands for this were pulled out of this guide:  
    # https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-cert-manager  
  
    # Command to initialize Vault  
    echo "Initializing Vault"  
    kubectl exec -n vault vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json > init-keys.json  
  
    # Set environmental variables for unseal key and root token  
    echo "Setting environmental variables for the Unseal Key and the Root Token"  
    export VAULT_UNSEAL_KEY=$(cat init-keys.json | jq -r ".unseal_keys_b64\[\]")  
    export VAULT_ROOT_TOKEN=$(cat init-keys.json | jq -r ".root_token")  
    echo "VAULT_UNSEAL_KEY = $VAULT_UNSEAL_KEY"  
    echo "VAULT_ROOT_TOKEN = $VAULT_ROOT_TOKEN"  
  
    # Unseal the vault  
    echo "Unseal Vault"  
    kubectl exec -n vault vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY  
  
    # Login with the root token  
    echo "Login with root token"  
    kubectl exec -n vault vault-0 -- vault login $VAULT_ROOT_TOKEN  
  
    # Enable the PKI secrets engine  
    echo "Enable the PKI secrets engine"  
    #kubectl exec --stdin=true --tty=true -n vault vault-0 -- vault secrets enable pki  
    kubectl exec -n vault vault-0 -- vault secrets enable pki  
  
    # Set the max age of a cert to be a year  
    echo "Tune vault to set the max age of a cert to be a year"  
    #kubectl exec --stdin=true --tty=true -n vault vault-0 -- vault secrets tune -max-lease-ttl=8760h pki  
    kubectl exec -n vault vault-0 -- vault secrets tune -max-lease-ttl=43800h pki  
  
    # Upload the pem bundle from /root/ca/vault_bundle.json on home lab server  
    echo "Upload PEM bundle to vault"  
    curl --header "X-Vault-Token: $VAULT_ROOT_TOKEN" --cacert /root/ca-cert/ca-chain.cert.pem --request POST --data "@/root/vault-data/vault_bundle_.json" https://vault:8200/v1/pki/config/ca  
  
    # Configure the PKI secrets engine certificate issuing and certificate revocations list endpoints to use the vault service the vault namespace:  
    echo "Configure the PKI secrets engine with issuer and CRL endpoints"  
    kubectl exec -n vault vault-0 -- vault write pki/config/urls issuer="home-lab-issuer"  issuing_certificates="http://vault.vault:8200/v1/pki/ca" crl_distribution_points="http://vault.vault:8200/v1/pki/crl"  
  
    # Create a role  
    echo "Create a home-lab-dot-local role in vault"  
    kubectl exec -n vault vault-0 -- vault write pki/roles/home-lab-dot-local allowed_domains=homelab.local allow_subdomains=true max_ttl=336h  
  
    # Copy policy file to vault container  
    echo "Copy home lab vault policy from job container to vault container"  
    kubectl cp /root/vault-data/vault_policy.hcl vault/vault-0:/vault/data/  
  
    # Create a policy which allows the newly created role to access the paths  
    echo "Create vault policy"  
    kubectl exec -n vault vault-0 -- vault policy write pki /vault/data/vault_policy.hcl  
  
    # This section will contain code to cut an intermediate off of the root created on home lab server  
    ######################################################################  
  
    echo "Create a new secrets engine in vault for the vault intermediate"  
    kubectl exec -n vault vault-0 -- vault secrets enable -path=pki_int pki  
      
    echo "Tune the new secrets engine"  
    kubectl exec -n vault vault-0 -- vault secrets tune -max-lease-ttl=8760h pki_int  
  
    echo "Generate an intermediate CSR"  
    kubectl exec -n vault vault-0 -- vault write -format=json pki_int/intermediate/generate/internal common_name="homelab.local Vault Intermediate" issuer_name="home-lab-dot-local-int" | jq -r '.data.csr' > pki_intermediate.csr  
  
    echo "Copy pki_intermediate.csr to the vault container"  
    kubectl cp pki_intermediate.csr vault/vault-0:/vault/data   
  
    echo "Sign the intermediate CSR with the intermediate key already in vault"  
    kubectl exec -n vault vault-0 -- vault write -format=json pki/root/sign-intermediate csr=@/vault/data/pki_intermediate.csr format=pem_bundle ttl="8760h" | jq -r '.data.certificate' > intermediate.cert.pem  
  
    echo "Copy the signed second intermediate certificate into the vault container"  
    kubectl cp intermediate.cert.pem vault/vault-0:/vault/data  
  
    echo "Import the intermediate certificate back into Vault"  
    kubectl exec -n vault vault-0 -- vault write pki_int/intermediate/set-signed certificate=@intermediate.cert.pem  
  
    echo "Create a role for the intermediate"  
    kubectl exec -n vault vault-0 -- vault write pki_int/roles/home-lab-dot-local allowed_domains=homelab.local allow_subdomains=true max_ttl=24h  
  
    # Copy policy file to vault container  
    echo "Copy home lab vault policy for the intermediate from job container to vault container"  
    kubectl cp /root/vault-data/vault_int_policy.hcl vault/vault-0:/vault/data/  
  
    # Create a policy which allows the newly created role to access the paths  
    echo "Create vault policy for the intermediate"  
    kubectl exec -n vault vault-0 -- vault policy write pki_int /vault/data/vault_int_policy.hcl  
  
    echo "Update issuing certificate endpoints for root and intermediate secret engines"  
    kubectl exec -n vault vault-0 -- vault write pki/config/urls issuing_certificates=http://vault.vault:8200/v1/pki/ca,http://vault.vault:8200/v1/pki_int/ca?issuing_ca=vault-ca crl_distribution_points=http://vault.vault:8200/v1/pki/crl,http://vault.vault:8200/v1/pki_int/crl  
    kubectl exec -n vault vault-0 -- vault write pki_int/config/urls issuing_certificates="http://vault.vault:8200/v1/pki/ca","http://vault.vault:8200/v1/pki_int/ca?issuing_ca=vault-ca" crl_distribution_points="http://vault.vault:8200/v1/pki/crl","http://vault.vault:8200/v1/pki_int/crl"  
  
    ######################################################################  
  
    # Enable Kubernetes authentication  
    echo "Enable Kubernetes authentication"  
    kubectl exec -n vault vault-0 -- vault auth enable kubernetes  
  
    # Set Kuberntes API endpoint  
    echo "Set Kubernetes API endpoint"  
    kubectl exec -n vault vault-0 -- vault write auth/kubernetes/config kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR"  
  
    # This part was confusing as the preferred method changed.  This below command is connecting a service account to the PKI policy  
    # Cert manager docs here - https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-cert-manager  
    # Info on the service account here - https://developer.hashicorp.com/vault/docs/auth/kubernetes#discovering-the-service-account-issuer  
    # Based on these two documents together, what's being bound is the default service account in the vault namespace  
  
    # The issuer service account needs to be placed in the cert-manager namespace so that the cert-manager ClusterIssuer has the proper access  
    echo "Bind the issuer service account to the PKI role"  
    kubectl exec -n vault vault-0 -- vault write auth/kubernetes/role/issuer bound_service_account_names=issuer bound_service_account_namespaces=cert-manager policies=pki_int ttl=87600h
```

At a very high level, this script:

*   [Initializes Vault](https://developer.hashicorp.com/vault/tutorials/getting-started/getting-started-deploy#initializing-the-vault)
*   Creates and tunes the PKI secrets engine
*   Uploads the pem bundle from the previous section to the Vault PKI secrets engine (this bundle gets mounted into the job via the `vault-data` volume)
*   Cuts and tunes an intermediate CA off of the CA in the PKI secrets engine
*   Enables Kubernetes authentication (required for the integration with Cert-Manager)

At this point, Vault is ready to go.

Cert-Manager Installation
=========================

The Cert-Manager installation does not require nearly as much tuning at Vault.

The `cert-manager` namespace was created imperatively in the cluster using `kubectl`:

```bash
kubectl create ns cert-manager
```

Cert-Manager requires CRDs in the cluster:

```bash
curl -L https://github.com/cert-manager/cert-manager/releases/download/v1.11.0/cert-manager.crds.yaml | kubectl apply -f -
```

Some supporting objects are also required in the `cert-manager` namespace:

```yaml
apiVersion: v1  
data:  
  ca-chain.cert.pem: <<<OMITTED>>  
kind: Secret  
metadata:  
  creationTimestamp: null  
  name: ca-bundle  
  namespace: cert-manager  
\---  
apiVersion: rbac.authorization.k8s.io/v1  
kind: ClusterRoleBinding  
metadata:  
  name: role-tokenreview-binding  
  namespace: cert-manager  
roleRef:  
  apiGroup: rbac.authorization.k8s.io  
  kind: ClusterRole  
  name: system:auth-delegator  
subjects:  
  - kind: ServiceAccount  
    name: issuer  
    namespace: cert-manager  
\---  
apiVersion: rbac.authorization.k8s.io/v1  
kind: Role  
metadata:  
  name: cert-manager-issuer  
  namespace: cert-manager  
rules:  
\- apiGroups: \["cert-manager.io"\]  
  resources: \["certificates", "certificaterequests"\]  
  verbs: \["create", "delete"\]  
\---  
apiVersion: rbac.authorization.k8s.io/v1  
kind: RoleBinding  
metadata:  
  name: cert-manager-issuer-binding  
  namespace: cert-manager  
subjects:  
\- kind: ServiceAccount  
  name: issuer  
  namespace: cert-manager  
roleRef:  
  kind: Role  
  name: cert-manager-issuer  
  apiGroup: rbac.authorization.k8s.io  
\---  
apiVersion: v1  
kind: ServiceAccount  
metadata:  
  name: issuer  
  namespace: cert-manager  
\---  
apiVersion: v1  
kind: Secret  
metadata:  
  name: issuer-token  
  namespace: cert-manager  
  annotations:  
    kubernetes.io/service-account.name: issuer  
type: kubernetes.io/service-account-token  
\---  
apiVersion: cert-manager.io/v1  
kind: ClusterIssuer  
metadata:  
  name: vault-issuer  
spec:  
  vault:  
    server: https://vault.vault:8200/   
    path: pki_int/sign/wsp-dot-local   
    caBundleSecretRef:   
      name: ca-bundle  
      key: ca-chain.cert.pem  
    auth:  
      kubernetes:  
        mountPath: /v1/auth/kubernetes  
        role: issuer  
        secretRef:  
          name: issuer-token  
          key: token  

```

These objects handle the following:

*   Create a CA bundle in the `cert-manager` namespace
*   Create a service account and RBAC to allow Cert-manager to create certificate objects
*   Create service-account-token to auth with Vault
*   Create `ClusterIssuer` object for Vault (this is the linchpin in the integration between Cert-Manager and Vault)

Cert-Manager was then installed via Helm:

```bash
helm repo add jetstack https://charts.jetstack.io  
helm upgrade -i cert-manager jetstack/cert-manager --version v1.11.0 \\  
\-f values.yaml -n cert-manager
```

If this was all done properly, the `vault-issuer` object should have a status of `Ready`:

```bash
$ kubectl get clusterissuers.cert-manager.io   
NAME           READY   AGE  
vault-issuer   True    12d
```

Testing the Integration
=======================

The simple [Podinfo](https://github.com/stefanprodan/podinfo) web application will be used to test this integration. If everything was done correctly, all that is needed is a couple of annotations on an ingress object. Based on those annotations, Cert-Manager will automatically create a TLS secret for that same ingress object to secure the HTTP endpoint.

As was done for Vault and Cert-manager, a namespace will be imperatively created, and then the application will be installed via Helm:

```bash
kubectl create ns podinfo  
helm repo add stefanprodan https://stefanprodan.github.io/podinfo  
helm upgrade -i my-podinfo stefanprodan/podinfo --version 6.4.0 \\  
\-f values.yaml -n podinfo
```

Here is the values.yaml file:

```yaml
ingress:  
      enabled: true  
      annotations:  
        cert-manager.io/cluster-issuer: vault-issuer  
        cert-manager.io/common-name: podinfo.wsp.local  
      hosts:  
        - host: podinfo.wsp.local  
          paths:  
            - path: /  
              pathType: ImplementationSpecific  
      tls:  
      - secretName: podinfo-wsp-cert  
        hosts:  
          - podinfo  
          - podinfo.wsp.local
```

The important lines in this values file are the annotations. The first annotation in the list points to the cluster-issuer to be used to create the cert, and the second declares the common-name/hostname to be used in the cert.

This cluster has an [HAproxy](https://haproxy-ingress.github.io/) ingress controller installed and serving traffic on 192.168.1.241:

```bash
$ kubectl get svc -n haproxy-ingress   
NAME                                                 TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)                      AGE  
haproxy-ingress-kubernetes-ingress-default-backend   ClusterIP      None           <none>          8080/TCP                     14d  
haproxy-ingress                                      LoadBalancer   10.43.36.104   192.168.1.241   80:31200/TCP,443:30533/TCP   15d
```

HAproxy is also the only and default ingress class in this cluster. This means that to hit this podinfo application, DNS in this environment needs to be updated so that `podinfo.wsp.local` resolves to 192.168.1.241. How to do that is potentially different in your environment if you are following along at home. I use [pi-hole](https://pi-hole.net/) and created a static entry for podinfo:

```bash
root@pidns01:/etc/dnsmasq.d # cat 99-self-managed.conf | grep podinfo  
address=/podinfo.wsp.local/192.168.1.241
```

With this in place, DNS should resolve to 192.168.1.241 for `podinfo.wsp.local`:

```bash
$ dig +short podinfo.wsp.local  
192.168.1.241
```

If you haven’t already done so, the local CA must be imported onto whatever host is doing this test. [Here is the procedure for MacOS](https://support.apple.com/guide/keychain-access/create-your-own-certificate-authority-kyca2686/mac).

And finally, a curl should work without specifying `-k` to ignore certificate errors:

```bash
$ curl https://podinfo.wsp.local  
{  
  "hostname": "podinfo-77f8ff8ccb-vqxch",  
  "version": "6.4.0",  
  "revision": "fcf573111bd82600052f99195a67f33d8242bf17",  
  "color": "#34577c",  
  "logo": "https://raw.githubusercontent.com/stefanprodan/podinfo/gh-pages/cuddle_clap.gif",  
  "message": "greetings from podinfo v6.4.0",  
  "goos": "linux",  
  "goarch": "amd64",  
  "runtime": "go1.20.5",  
  "num_goroutine": "9",  
  "num_cpu": "8"  
}
```

Sweet, it works!

Conclusion
==========

This post by no means provides a perfect solution for this integration, but it does provide a starting point. There are a couple of items that are fine in a home lab but suboptimal in the best case and borderline reckless in the worst case for production environments. Even though Helm commands were shown for all of the application installations in this post, the installs are actually done via [Flux HelmRelease objects](https://fluxcd.io/flux/components/helm/helmreleases/). With that said, here are some areas I hope to improve over time:

*   Make the Vault bootstrapping a Flux post-deploy job
*   Rotate the token used for the Cert-manager to Vault authentication (it’s currently valid for 10 years)
*   Import the root CA directly into Vault instead of an intermediate thus resulting in multiple intermediates in the chain

Despite these items, I hope you found this blog post helpful. Thanks for reading!
