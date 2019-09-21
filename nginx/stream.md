    stream {
        upstream k8s_6443 {
            server 192.168.20.31:6443;
            server 192.168.20.32:6443;
            server 192.168.20.33:6443;
        }

        server {
            listen 6443;

            proxy_pass k8s_6443;
        }
    }