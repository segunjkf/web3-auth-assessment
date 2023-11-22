# Namespace configuration for Cassandra
resource "kubernetes_namespace" "cassandra" {
  metadata {
    name = var.namespace
  }
}

# Secret configuration for Cassandra admin credentials
resource "kubernetes_secret" "cassandra_admin_secret" {
  metadata {
    name      = "cassandra-admin-secret"
    namespace = var.namespace
  }

  data = {
    "username" = base64encode("cassandra-admin")
    "password" = base64encode("cassandra-admin-password")
  }
  depends_on = [ kubernetes_namespace.cassandra ]
}

# HAproxy Ingress configuration
resource "helm_release" "haproxy_ingress" {
  name             = "haproxy-ingress"
  repository       = "https://haproxytech.github.io/helm-charts"
  chart            = "kubernetes-ingress"
  create_namespace = true
  version          = "1.16.2"

  set {
    name  = "controller.kind"
    value = "DaemonSet"
  }

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.stats.enabled"
    value = "true"
  }

  set {
    name  = "controller.stats.port"
    value = "1024"
  }

  # Enabling header-based session stickiness
  set {
    name  = "controller.config.cookie-persistence"
    value = "cookie"
  }

  set {
    name  = "controller.config.load-balance"
    value = "leastconn"
  }
}

# Cert Manager configuration for TLS certificates
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }
}

# K8ssandra Operator for managing Cassandra
resource "helm_release" "k8ssandra_operator" {
  name             = "k8ssandra-operator"
  repository       = "https://helm.k8ssandra.io/stable"
  chart            = "k8ssandra/k8ssandra-operator"
  namespace        = var.namespace

  set {
    name  = "global.clusterScoped"
    value = "true"
  }

  set {
    name  = "controlPlane"
    value = "false"
  }

  values = [<<EOF
  cassandra:
    auth:
      superuser:
        secret: cassandra-admin-secret
    cassandraLibDirVolume:
      storageClass: standard-rwo
    clusterName: mixed-workload
    datacenters:
    - name: dc1
      size: 3
      racks:
      - name: rack1
        affinityLabels:
          failure-domain.beta.kubernetes.io/zone: us-central1-a
      - name: rack2
        affinityLabels:
          failure-domain.beta.kubernetes.io/zone: us-central1-b
  EOF
  ]
  depends_on = [ kubernetes_namespace.cassandra ]
}
