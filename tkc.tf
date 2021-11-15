#
# TKC Demo
#
#  John D. Allen
#  Global Solutions Architect - Cloud, IOT, & Automation
#  A10 Networks, Inc.
#  Apache v2.0 License applies.
#  June, 2021
#

provider "kubernetes" {
  config_path = var.prov_config_path
}

#------------------------------------------------------------------#
resource "kubernetes_namespace" "cyan" {
  depends_on = [
    thunder_virtual_server.ws-vip
  ]
  metadata {
    name = "cyan"
  }
}

#------------------------------------------------------------------#
resource "kubernetes_cluster_role_binding" "rbac" {
  metadata {
    name = "th-secret-rbac"
  }
  subject {
    kind = "ServiceAccount"
    name = "default"
    namespace = kubernetes_namespace.cyan.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = "cluster-admin"
  }
}

#------------------------------------------------------------------#
resource "kubernetes_secret" "thunder-secret" {
  metadata {
    name = "thunder-access-creds"
  }
  data = {
    username = var.thunder_username
    password = var.thunder_password
  }
}

#------------------------------------------------------------------#
resource "kubernetes_config_map" "ws-config" {
  depends_on = [
    kubernetes_namespace.cyan
  ]
  metadata {
    name = "ws-conf-file"
    namespace = kubernetes_namespace.cyan.metadata[0].name
  }
  data = {
    "ws.conf" = <<EOF
    server {
        listen 80 default_server;
        server_name app_server;
        
        root /usr/share/nginx/html;
        error_log /var/log/nginx/app-server-error.log notice;
        index index.html;
        expires -1;
        
        sub_filter_once off;
        sub_filter 'server_hostname' '$hostname';
        sub_filter 'server_address'  '$server_addr:$server_port';
        sub_filter 'remote_addr'     '$remote_addr:$remote_port';
        sub_filter 'client_browser'  '$http_user_agent';
        sub_filter 'document_root'   '$document_root';
        sub_filter 'proxied_for_ip'  '$http_x_forwarded_for';
    }
    EOF
  }
}

#------------------------------------------------------------------#
resource "kubernetes_config_map" "ws-index" {
  depends_on = [
    kubernetes_namespace.cyan
  ]
  metadata {
    name = "ws-index-file"
    namespace = kubernetes_namespace.cyan.metadata[0].name
  }
  data = {
    "index.html" = <<EOF
    <!DOCTYPE html>
    <html>
        <head>
            <title>A10 Testing Webpage</title>
            <style>
                body {
                    margin: 0px;
                    font: 20px 'RobotoRegular', Arial, sans-serif;
                    font-weight: 100;
                    height: 100%;
                    color: #000000;
                }
                img {
                    width: 200px;
                    margin: 35px auto 35px auto;
                    display:block;
                }
                div.disp {
                    display: table;
                    background: #D8FEFC;
                    padding: 20px 20px 20px 20px;
                    border: 2px black;
                    border-radius: 12px;
                    margin: 0px auto auto auto;
                }
                div.disp p {
                    display: table-row;
                    margin: 5px auto auto auto;
                }
                div.disp p span {
                    display: table-cell;
                    padding: 10px;
                }
                h1, h2 {
                    font-weight: 100;
                }
                div.check {
                    padding: 0px 0px 0px 0px;
                    display: table;
                    margin: 35px auto auto auto;
                    font: 12px 'RobotoRegular', Arial, sans-serif;
                }
                #center {
                    width: 400px;
                    margin: 0 auto;
                    font: 12px Courier;
                }
            </style>
            <script>
                var ref;
                function checkRefresh() {
                    if (document.cookie == "refresh=1") {
                        document.getElementById("check").checked = true;
                        ref = setTimeout(function(){location.reload();}, 500);
                    } 
                }
                function changeCookie() {
                    if (document.getElementById("check").checked) {
                        document.cookie = "refresh=1";
                        ref = setTimeout(function(){location.reload();}, 500);
                    } else {
                        document.cookie = "refresh=0";
                        clearTimeout(ref);
                    }
                }
            </script>
        </head>
        <body onload="checkRefresh();">
            <div class="disp">
                <br>
                <h2>A10 Webserver Demo Page</h2>
                <p><span>This is a test web page running on a Kubernetes Cluster.</span></p>
                <p><span>Server Name:</span> <span>server_hostname</span></p>
                <p><span>Server Address:</span> <span>server_address</span></p>
                <p><span>UA:</span> <span>client_browser</span></p>
            </div>
            <div class="check">
                <input type="checkbox" id="check" onchange="changeCookie()"> Auto Refresh</input>
            </div>
        </body>
    </html>
    EOF
  }
}

#------------------------------------------------------------------#
resource "kubernetes_deployment" "webservers" {
  depends_on = [
    kubernetes_config_map.ws-config,
    kubernetes_config_map.ws-index
  ]
  metadata {
    name = "webserver"
    namespace = kubernetes_namespace.cyan.metadata[0].name
  }
  spec {
    selector {
      match_labels = {
        app = "webserver"
      }
    }
    replicas = 3
    template {
      metadata {
        labels = {
          app = "webserver"
        }
      }
      spec {
        container {
          name = "nginx"
          image = "nginx:latest"
          image_pull_policy = "IfNotPresent"
          port {
            container_port = 80
          }
          volume_mount {
            mount_path = "/usr/share/nginx/html/index.html"
            sub_path = "index.html"
            read_only = true
            name = "ws-index-file"
          }
          volume_mount {
            mount_path = "/etc/nginx/conf.d/"
            read_only = true
            name = "ws-conf-file"
          }
        }
        volume {
          name = "ws-index-file"
          config_map {
            name = "ws-index-file"
            items {
              key = "index.html"
              path = "index.html"
            }
          }
        }
        volume {
          name = "ws-conf-file"
          config_map {
            name = "ws-conf-file"
            items {
              key = "ws.conf"
              path = "ws.conf"
            }
          }
        }
      }
    }
  }
}

#------------------------------------------------------------------#
resource "kubernetes_service" "webserverSvc" {
  depends_on = [
    kubernetes_deployment.webservers
  ]
  metadata {
    name = "webserver-svc"
    namespace = kubernetes_namespace.cyan.metadata[0].name
  }
  spec {
    selector = {
      app = "webserver"
    }
    type = "NodePort"
    port {
      name = "http-port"
      protocol = "TCP"
      port = "8080"
      target_port = "80"
    }
  }
}

#------------------------------------------------------------------#
resource "kubernetes_ingress" "tkcIngress" {
  depends_on = [
    kubernetes_deployment.webservers,
    kubernetes_service.webserverSvc
  ]
  metadata {
    name = "ingress-resource"
    namespace = kubernetes_namespace.cyan.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = "a10-ext"
      "webserver-svc.acos.a10networks.com/service-group" = "{\"name\":\"ws-sg\",\"protocol\":\"tcp\",\"disableMonitor\":true}"
      "acos.a10networks.com/virtual-server" = "{\"name\":\"ws-vip\",\"vip\":\"${var.thunder_vip}\"}"
      "acos.a10networks.com/virtual-ports" = "[{\"port\":\"443\",\"protocol\":\"https\",\"http2\":false,\"snat\":true}]"
    }
  }
  spec {
    rule {
      host = "*.gan"
      http {
        path {
          path = "/"
          backend {
            service_name = "webserver-svc"
            service_port = 8080
          }
        }
      }
    }
  }
}

#------------------------------------------------------------------#
resource "kubernetes_deployment" "tkc" {
  depends_on = [
    kubernetes_ingress.tkcIngress,
    kubernetes_secret.thunder-secret
  ]
  metadata {
    name = "thunder-kubernetes-connector"
  }
  spec {
    selector {
      match_labels = {
        app = "thunder-kubernetes-connector"
      }
    }
    replicas = 1
    template {
      metadata {
        labels = {
          app = "thunder-kubernetes-connector"
        }
      }
      spec {
        container {
          name = "thunder-kubernetes-connector"
          image = "a10harmony/a10-kubernetes-connector:1.9"
          image_pull_policy = "IfNotPresent"
          env {
            name = "POD_NAMESPACE"
            value = "default"
          }
          env {
            name = "WATCH_NAMESPACE"
            value = kubernetes_namespace.cyan.metadata[0].name
          }
          env {
            name = "CONTROLLER_URL"
            value = "https://${var.thunder_ip_address}"
          }
          env {
            name = "ACOS_USERNAME_PASSWORD_SECRETNAME"
            value = kubernetes_secret.thunder-secret.metadata[0].name
          }
          args = [
            "--watch-namespace=$(WATCH_NAMESPACE)",
            "--use-node-external-ip=true",
            "--patch-to-update=true",
            "--safe-acos-delete=true",
            "--use-ingress-class-only=true",
            "--ingress-class=a10-ext"
          ]
        }
      }
    }
  }
}

