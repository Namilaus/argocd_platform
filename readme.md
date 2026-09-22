# Argo CD Homelab Platform

This repository contains the GitOps configuration for my personal Kubernetes homelab.

The goal of this project is to learn Kubernetes and Argo CD through practical experimentation. I use the homelab to test ideas, deploy services, troubleshoot problems, and connect Kubernetes theory with real-world usage.

## What This Repository Provides

- Argo CD configuration for GitOps deployments
- Kubernetes manifests and Helm charts
- Application deployments for homelab services
- Storage, networking, ingress, and TLS configuration
- A safe environment for learning through trial and error
- Version-controlled infrastructure changes

## Homelab Goals

This project is mainly a learning environment. I use it to:

- Understand Kubernetes resources and their relationships
- Learn how deployments, services, PVCs, and ingress work
- Practice GitOps workflows with Argo CD
- Experiment with Helm and Kustomize
- Learn how applications communicate inside Kubernetes
- Test storage and networking solutions
- Troubleshoot failures and improve the configuration over time
- Apply Kubernetes theory in practical situations

Mistakes and experiments are expected. Changes may be added, tested, adjusted, or removed as part of the learning process.

## Main Components

The repository currently contains configuration for:

- Argo CD
- Cert-manager
- Storage and S3-compatible storage
- Databases
- Mail services
- NetBird
- Nextcloud
- Web applications
- Ingress and HTTP routing

The configuration is organized into platform components, applications, and older experiments.

## Repository Structure

```text
apps/          Application manifests and Helm values
argocd/        Argo CD applications and ApplicationSets
platform/      Shared platform services such as certificates and storage
terraform/     Hetzner Cloud and K3s infrastructure
old_but_gold/  Previous experiments and older working configurations
apps-ntd/      Additional or unfinished application configuration
```

## Setup

The cluster is created with Terraform on Hetzner Cloud. The bootstrap scripts install K3s on one control-plane node and two workers.

The rebuild steps are documented in [setup.md](setup.md). Secrets, kubeconfig files, and Terraform variables stay outside Git.