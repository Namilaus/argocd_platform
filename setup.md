# Rebuilding the Homelab

This is how I rebuild the cluster when I need to start over. The infrastructure runs on Hetzner Cloud, and the Kubernetes cluster is K3s with one control-plane node and two workers. Argo CD then takes over the applications from this repository.

The order matters a little. I first create the servers, then connect `kubectl`, install Argo CD, create the secrets that cannot live in Git, and finally let Argo CD deploy the platform and applications.

## Prerequisites

Before starting, I make sure these tools are available on my workstation:


I also need the following outside the repository:


I keep all of these values out of Git. That includes API tokens, S3 credentials, the kubeconfig, and Terraform state.

## Provision K3s

```powershell
cd terraform
```

I create or update `terraform.tfvars` locally. This file is intentionally not committed:

```hcl
hcloudtoken         = "<hetzner-api-token>"
ssh_public_key_path = "~/.ssh/id_ed25519.pub"
```

At the moment, Terraform creates one control plane at `10.0.0.2`, two workers at `10.0.0.3` and `10.0.0.4`, and a private network using `10.0.0.0/24`.

Initialize, validate, review, and apply:

```powershell
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

On first boot, the bootstrap scripts configure the private interface `enp7s0`, wait until the assigned private IP is available, and install K3s. The control plane pins Flannel to that private interface. Each worker waits for the control-plane API before joining the cluster.

### When I change a bootstrap script

Cloud-init runs `user_data` during the first boot only. Editing a `.tftpl` file therefore does not rerun the script on a server that already exists.

For a clean replacement of one node, use a targeted replacement instead of destroying the whole project:

```powershell
terraform apply -replace='hcloud_server.k3s-control-plane["control-plane"]'
terraform apply -replace='hcloud_server.k3s-workers["worker-01"]'
terraform apply -replace='hcloud_server.k3s-workers["worker-02"]'
```

Replacing the control plane can also mean replacing the workers, because their bootstrap process joins that control plane. I run `terraform plan` first and check the proposed changes before applying them.


## Install Argo CD

Argo CD is the first component I install inside the cluster. It will later create and manage the applications described in `argocd/applicationset.yaml`.

```powershell
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd wait --for=condition=Available deployment/argocd-server --timeout=10m
kubectl -n argocd get pods
```

The initial admin password is stored in a Kubernetes secret. I retrieve it like this:

```powershell
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | %{ [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_)) }
```

## Create the secrets that stay outside Git

The manifests refer to credentials that should not be stored in this repository. I create those secrets manually before syncing the dependent resources.

First I create the Cloudflare secret. Cert-manager needs it later when it requests the `atayi.net` certificate:

```powershell
kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -
kubectl -n cert-manager create secret generic cloudflare-api-token-secret `
	--from-literal=api-token='<cloudflare-api-token>'
```

Then I create the S3 secret in the `storage` namespace:

```powershell
kubectl create namespace storage --dry-run=client -o yaml | kubectl apply -f -
kubectl -n storage create secret generic csi-s3-secret `
	--from-literal=accessKey='<s3-access-key>' `
	--from-literal=secretKey='<s3-secret-key>' `
	--from-literal=endpoint='https://storage.yandexcloud.net'
```

The secret name and namespace must stay `storage/csi-s3-secret`, because that is what the storage configuration expects. The key names may need to change if I switch CSI-S3 providers.

## Let Argo CD deploy the platform

Now I register the cert-manager Application and the ApplicationSet:

```powershell
kubectl apply -f argocd/cert-manager-application.yaml
kubectl apply -f argocd/applicationset.yaml
kubectl -n argocd get applications
kubectl -n argocd get applicationsets
```

The ApplicationSet watches `apps/*` in the GitHub repository and creates one Argo CD Application per directory. The cert-manager chart creates the `letsencrypt-prod` ClusterIssuer.

After cert-manager is ready, I apply the route for Argo CD:

```powershell
kubectl get clusterissuer letsencrypt-prod
kubectl apply -f argocd/http_route.yaml
```

The DNS record for `*.atayi.net` must point to the control-plane public IP. Otherwise the route and certificate can be healthy inside Kubernetes while the hostname still does not work externally.

## Install S3 storage

The S3 CSI driver is installed separately from the Argo CD applications:

Build the chart dependency and install the CSI driver:

```powershell
helm dependency build platform/storage/csi-s3
helm upgrade --install csi-s3 platform/storage/csi-s3 `
	--namespace storage `
	--create-namespace
```

Create the repository's StorageClass:

```powershell
kubectl apply -f platform/storage/s3.yaml
kubectl get storageclass
kubectl -n storage get pods
```

The resulting StorageClass is named `s3-ionos` and uses the `k3s-bucket` bucket. Applications reference the `csi-s3-secret` secret in the `storage` namespace.

## Check that everything came up

```powershell
kubectl get nodes -o wide
kubectl get pods -A
kubectl get applications -n argocd
kubectl get ingress -A
kubectl get clusterissuer letsencrypt-prod
kubectl get certificate -A
kubectl get storageclass
```

These commands are useful when something is stuck:

```powershell
kubectl describe node <node-name>
kubectl -n argocd get events --sort-by=.lastTimestamp
kubectl -n cert-manager logs deployment/cert-manager
kubectl -n storage get events --sort-by=.lastTimestamp
```