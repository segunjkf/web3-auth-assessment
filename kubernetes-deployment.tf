# Namespace configuration for Cassandra
resource "kubernetes_namespace" "cassandra" {
  metadata {
    name = var.namespace
  }
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
  chart            = "k8ssandra-operator"
  create_namespace = true

  set {
    name  = "global.clusterScoped"
    value = "true"
  }

  set {
    name  = "controlPlane"
    value = "false"
  }
  depends_on = [ helm_release.cert_manager ]
}

// Create cassandra mutli zone cluster
resource "kubectl_manifest" "cassandra" {
    yaml_body = <<YAML
apiVersion: k8ssandra.io/v1alpha1
kind: K8ssandraCluster
metadata:
  name: cassandra
  namespace: "${var.namespace}"
spec:
  cassandra:
    serverVersion: "3.11.14"
    storageConfig:
      cassandraDataVolumeClaimSpec:
        storageClassName: standard
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 5Gi
    telemetry:
      vector:
        enabled: true
        components:
          transforms:
            - name: my-transform
              type: remap
              inputs:
                - cassandra_metrics
              config: |-
                source = ".tags.host = get_hostname!()"
          sinks:
            - name: console
              inputs:
                - my-transform
              type: console
              config: |-
                [sinks.console.encoding]
                codec = "json"
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 100m
            memory: 128Mi
    config:
      cassandraYaml:
        auto_snapshot: false
        memtable_flush_writers: 1
        commitlog_segment_size_in_mb: 2
        concurrent_compactors: 1
        compaction_throughput_mb_per_sec: 0
        sstable_preemptive_open_interval_in_mb: 0
        key_cache_size_in_mb: 0
        thrift_prepared_statements_cache_size_mb: 1
        prepared_statements_cache_size_mb: 1
        slow_query_log_timeout_in_ms: 0
        cas_contention_timeout_in_ms: 10000
        counter_write_request_timeout_in_ms: 10000
        range_request_timeout_in_ms: 10000
        read_request_timeout_in_ms: 10000
        request_timeout_in_ms: 10000
        truncate_request_timeout_in_ms: 60000
        write_request_timeout_in_ms: 10000
        counter_cache_size_in_mb: 0
        concurrent_reads: 2
        concurrent_writes: 2
        concurrent_counter_writes: 2
      jvmOptions:
        heapSize: 512Mi
        heapNewGenSize: 256Mi
        gc: CMS
    networking:
      hostNetwork: true
    mgmtAPIHeap: 64Mi
    datacenters:
      - metadata:
          name: dc1
        k8sContext: kind-k8ssandra-0
        size: 2
        racks:
          - name: rack1
            nodeAffinityLabels:
              "topology.kubernetes.io/zone": us-central1-a
          - name: rack2
            nodeAffinityLabels:
              "topology.kubernetes.io/zone": us-central1-b
      
YAML

depends_on = [ helm_release.k8ssandra_operator ]
}
