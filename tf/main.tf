resource "kubernetes_service" "zookeeper_headless" {
  metadata {
    name      = "k-zookeeper-headless"
    namespace = "kk"
    labels    = { app = "${var.kafka_name}-zookeeper" }
  }
  spec {
    port {
      name        = "client"
      protocol    = "TCP"
      port        = 2181
      target_port = "client"
    }
    port {
      name        = "election"
      protocol    = "TCP"
      port        = 3888
      target_port = "election"
    }
    port {
      name        = "server"
      protocol    = "TCP"
      port        = 2888
      target_port = "server"
    }
    selector   = { app = "k-zookeeper" }
    cluster_ip = "None"
  }
}

resource "kubernetes_service" "zookeeper" {
  metadata {
    name      = "$k-zookeeper"
    namespace = "kk"
    labels    = { app = "k-zookeeper" }
  }
  spec {
    port {
      name        = "client"
      protocol    = "TCP"
      port        = 2181
      target_port = "client"
    }
    selector = { app = "k-zookeeper" }
    type     = "ClusterIP"
  }
}

resource "kubernetes_service" "kafka" {
  metadata {
    name      = "k"
    namespace = "kk"
    labels    = { app = "k" }
  }
  spec {
    port {
      name        = "broker"
      port        = 9092
      target_port = "kafka"
    }
    selector = { app = "k" }
  }
}

resource "kubernetes_service" "kafka_headless" {
  metadata {
    name        = "k-headless"
    namespace   = "kk"
    labels      = { app = "k" }
    annotations = { "service.alpha.kubernetes.io/tolerate-unready-endpoints" = "true" }
  }
  spec {
    port {
      name = "broker"
      port = 9092
    }
    selector   = { app = "k" }
    cluster_ip = "None"
  }
}

resource "kubernetes_stateful_set" "zookeeper" {
  metadata {
    name      = "k-zookeeper"
    namespace = "kk"
    labels    = { app = "${var.kafka_name}-zookeeper", component = "server" }
  }
  spec {
    replicas = "${var.zookeeper_cluster_size}"
    selector {
      match_labels = { app = "k-zookeeper", component = "server" }
    }
    template {
      metadata {
        labels = { app = "k-zookeeper", component = "server" }
      }
      spec {
        volume {
          name = "config"
          config_map {
            name         = "k-zookeeper"
            default_mode = "0555"
          }
        }
        volume {
          name = "data"
        }
        container {
          name    = "zookeeper"
          image   = "zookeeper:3.5.5"
          command = ["/bin/bash", "-xec", "/config-scripts/run"]
          port {
            name           = "client"
            container_port = 2181
            protocol       = "TCP"
          }
          port {
            name           = "election"
            container_port = 3888
            protocol       = "TCP"
          }
          port {
            name           = "server"
            container_port = 2888
            protocol       = "TCP"
          }
          env {
            name  = "ZK_REPLICAS"
            value = "3"
          }
          env {
            name  = "JMXAUTH"
            value = "false"
          }
          env {
            name  = "JMXDISABLE"
            value = "false"
          }
          env {
            name  = "JMXPORT"
            value = "1099"
          }
          env {
            name  = "JMXSSL"
            value = "false"
          }
          env {
            name  = "ZK_HEAP_SIZE"
            value = "1G"
          }
          env {
            name  = "ZK_SYNC_LIMIT"
            value = "10"
          }
          env {
            name  = "ZK_TICK_TIME"
            value = "2000"
          }
          env {
            name  = "ZOO_AUTOPURGE_PURGEINTERVAL"
            value = "0"
          }
          env {
            name  = "ZOO_AUTOPURGE_SNAPRETAINCOUNT"
            value = "3"
          }
          env {
            name  = "ZOO_INIT_LIMIT"
            value = "5"
          }
          env {
            name  = "ZOO_MAX_CLIENT_CNXNS"
            value = "60"
          }
          env {
            name  = "ZOO_PORT"
            value = "2181"
          }
          env {
            name  = "ZOO_STANDALONE_ENABLED"
            value = "false"
          }
          env {
            name  = "ZOO_TICK_TIME"
            value = "2000"
          }
          volume_mount {
            name       = "data"
            mount_path = "/data"
          }
          volume_mount {
            name       = "config"
            mount_path = "/config-scripts"
          }
          liveness_probe {
            exec {
              command = ["sh", "/config-scripts/ok"]
            }
            initial_delay_seconds = 20
            timeout_seconds       = 5
            period_seconds        = 30
            success_threshold     = 1
            failure_threshold     = 2
          }
          readiness_probe {
            exec {
              command = ["sh", "/config-scripts/ready"]
            }
            initial_delay_seconds = 20
            timeout_seconds       = 5
            period_seconds        = 30
            success_threshold     = 1
            failure_threshold     = 2
          }
          image_pull_policy = "IfNotPresent"
        }
        termination_grace_period_seconds = 1800
        security_context {
          run_as_user = 1000
          fs_group    = 1000
        }
      }
    }
    volume_claim_template {
      metadata {
        name = "data"
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "k_storage_class_name"
        resources {
          requests = { storage = "k_zookeeper_storage_size}" }
        }
      }
    }
    service_name = "k-zookeeper-headless"
    update_strategy {
      type = "RollingUpdate"
    }
  }
}

resource "kubernetes_stateful_set" "kafka" {
  metadata {
    name      = "k"
    namespace = "kk"
    labels    = { app = "k" }
  }
  spec {
    replicas = "1"
    selector {
      match_labels = { app = "k" }
    }
    template {
      metadata {
        labels = { app = "k" }
      }
      spec {
        container {
          name    = "kafka-broker"
          image   = "confluentinc/cp-kafka:${var.confluent_kafka_version}"
          command = ["sh", "-exc", "unset KAFKA_PORT && \\\nexport KAFKA_BROKER_ID=$${POD_NAME##*-} && \\\nexport KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://$${POD_IP}:9092 && \\\nexec /etc/confluent/docker/run\n"]
          port {
            name           = "kafka"
            container_port = 9092
          }
          env {
            name = "POD_IP"
            value_from {
              field_ref {
                field_path = "status.podIP"
              }
            }
          }
          env {
            name = "POD_NAME"
            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }
          }
          env {
            name = "POD_NAMESPACE"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }
          env {
            name  = "KAFKA_HEAP_OPTS"
            value = "-Xmx1G -Xms1G"
          }
          env {
            name  = "KAFKA_ALLOW_AUTO_CREATE_TOPICS"
            value = "${var.allow_auto_create_topics}"
          }
          env {
            name  = "KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR"
            value = "${var.offset_topic_replication_factor}"
          }
          env {
            name  = "KAFKA_DEFAULT_REPLICATION_FACTOR"
            value = "${var.default_replication_factor}"
          }
          env {
            name  = "KAFKA_MIN_INSYNC_REPLICAS"
            value = "${var.min_insync_replicas}"
          }
          env {
            name  = "KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR"
            value = "${var.transaction_state_log_replication_factor}"
          }
          env {
            name  = "KAFKA_TRANSACTION_STATE_LOG_MIN_ISR"
            value = "${var.transaction_state_log_min_isr}"
          }
          env {
            name  = "KAFKA_ZOOKEEPER_CONNECT"
            value = "${var.kafka_name}-zookeeper:2181"
          }
          env {
            name  = "KAFKA_LOG_DIRS"
            value = "/opt/kafka/data/logs"
          }
          env {
            name  = "KAFKA_CONFLUENT_SUPPORT_METRICS_ENABLE"
            value = "false"
          }
          env {
            name  = "KAFKA_JMX_PORT"
            value = "5555"
          }
          volume_mount {
            name       = "datadir"
            mount_path = "/opt/kafka/data"
          }
          liveness_probe {
            exec {
              command = ["sh", "-ec", "/usr/bin/jps | /bin/grep -q SupportedKafka"]
            }
            initial_delay_seconds = 30
            timeout_seconds       = 5
          }
          readiness_probe {
            tcp_socket {
              port = "kafka"
            }
            initial_delay_seconds = 30
            timeout_seconds       = 5
            period_seconds        = 10
            success_threshold     = 1
            failure_threshold     = 3
          }
          image_pull_policy = "IfNotPresent"
        }
        termination_grace_period_seconds = 60
      }
    }
    volume_claim_template {
      metadata {
        name = "datadir"
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "standard"
        resources {
          requests = { storage = "1Gi" }
        }
      }
    }
    service_name          = "k-headless"
    pod_management_policy = "OrderedReady"
    update_strategy {
      type = "OnDelete"
    }
  }
}

resource "kubernetes_deployment" "kafka_rest" {
  count = var.kafka_rest_enabled ? 1 : 0
  metadata {
    name      = "k-rest"
    namespace = "kk"
    labels = {
      app     = "k-rest"
      release = "k-rest"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app     = "k-rest"
        release = "k-rest"
      }
    }

    template {
      metadata {
        labels = {
          app     = "k-rest"
          release = "k-rest"
        }

        annotations = {
          "prometheus.io/port"   = "5556"
          "prometheus.io/scrape" = "true"
        }
      }

      spec {
        volume {
          name = "jmx-config"

          config_map {
            name = "k-rest-jmx-configmap"
          }
        }

        container {
          name    = "prometheus-jmx-exporter"
          image   = "solsson/kafka-prometheus-jmx-exporter@sha256:6f82e2b0464f50da8104acd7363fb9b995001ddff77d248379f8788e78946143"
          command = ["java", "-XX:+UnlockExperimentalVMOptions", "-XX:+UseCGroupMemoryLimitForHeap", "-XX:MaxRAMFraction=1", "-XshowSettings:vm", "-jar", "jmx_prometheus_httpserver.jar", "5556", "/etc/jmx-kafka-rest/jmx-kafka-rest-prometheus.yml"]

          port {
            container_port = 5556
          }

          volume_mount {
            name       = "jmx-config"
            mount_path = "/etc/jmx-kafka-rest"
          }

          image_pull_policy = "IfNotPresent"
        }

        container {
          name  = "k-rest-server"
          image = "confluentinc/cp-kafka-rest:5.4.0"

          port {
            name           = "rest-proxy"
            container_port = 8082
            protocol       = "TCP"
          }

          port {
            name           = "jmx"
            container_port = 5555
          }

          env {
            name = "KAFKA_REST_HOST_NAME"

            value_from {
              field_ref {
                field_path = "status.podIP"
              }
            }
          }

          env {
            name  = "KAFKA_REST_ZOOKEEPER_CONNECT"
            value = "k-zookeeper-headless:2181"
          }

          env {
            name  = "KAFKA_REST_SCHEMA_REGISTRY_URL"
            value = "k-schema-registry:8081"
          }

          env {
            name  = "KAFKAREST_HEAP_OPTS"
            value = "-Xms512M -Xmx512M"
          }

          env {
            name  = "KAFKA_REST_JMX_PORT"
            value = "5555"
          }

          image_pull_policy = "IfNotPresent"
        }
      }
    }
  }
}

resource "kubernetes_ingress" "kafka_rest_ingress" {
  count = var.kafka_rest_enabled && var.kafka_rest_ingress_enabled ? 1 : 0
  metadata {
    name      = "k-rest-ingress"
    namespace = "kk"
    labels = {
      app     = "l-rest"
      release = "k-rest"
    }

    annotations = {
      for instance in var.kafka_rest_ingress_annotations :
      instance.key => instance.value
    }
  }

  spec {
    tls {
      hosts       = ["mydearhost.io"]
      secret_name = "kk-tls-cert"
    }

    rule {
      host = "mydearhost.io"

      http {
        path {
          path = "/kafka(/|$)(.*)"

          backend {
            service_name = "k-rest-service"
            service_port = "8082"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "kafka_rest_service" {
  count = var.kafka_rest_enabled ? 1 : 0
  metadata {
    name      = "k-rest-service"
    namespace = "kk"
    labels = {
      app     = "k-rest"
      release = "k-rest"
    }
  }

  spec {
    port {
      name = "rest-proxy"
      port = 8082
    }

    selector = {
      app     = "k-rest"
      release = "k-rest"
    }
  }
}


resource "kubernetes_config_map" "kafka_rest_jmx_configmap" {
  count = var.kafka_rest_enabled ? 1 : 0
  metadata {
    name      = "k-rest-jmx-configmap"
    namespace = "kk"
    labels = {
      app     = "k-rest"
      release = "k-rest"
    }
  }

  data = {
    "jmx-kafka-rest-prometheus.yml" = "jmxUrl: service:jmx:rmi:///jndi/rmi://localhost:5555/jmxrmi                                                                                                \nlowercaseOutputName: true                                                                                                                                  \nlowercaseOutputLabelNames: true                                                                                                                            \nssl: false                                                                                                                                                 \nrules:                                                                     \n- pattern : 'kafka.rest<type=jetty-metrics>([^:]+):'                                                                                                       \n  name: \"cp_kafka_rest_jetty_metrics_$1\"                                                                                                                   \n- pattern : 'kafka.rest<type=jersey-metrics>([^:]+):'                                                                                                      \n  name: \"cp_kafka_rest_jersey_metrics_$1\"\n"
  }
}
