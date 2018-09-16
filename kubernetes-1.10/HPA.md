# HPA

### Horizontal Pod Autoscaler

## Stages
#### 1. Edit file /etc/kubernetes/apiserver

- 添加以下参数至 **KUBE_API_ARGS**

      --requestheader-client-ca-file=/etc/kubernetes/ssl/ca.pem \
      --proxy-client-cert-file=/etc/kubernetes/ssl/kubelet.pem \
      --proxy-client-key-file=/etc/kubernetes/ssl/kubelet.key \
      --requestheader-allowed-names=admin \
      --requestheader-extra-headers-prefix=X-Remote-Extra- \
      --requestheader-group-headers=X-Remote-Group \
      --requestheader-username-headers=X-Remote-User"
      
  - --requestheader-client-ca-file **使用集群CA证书**
  - --proxy-client-cert-file **使用kubelet 证书**
  - --proxy-client-key-file **使用kubelet key** 
  - --requestheader-allowed-names **设置为 admin**, 与 kubelet 证书 CN 字段相同
    - 否则会得到下述错误
      - x509: subject with cn=admin is not in the allowed list: [aggregator]

- **如 API Server 节点上未运行 kube-proxy, 则需要添加下述参数**

      --enable-aggregator-routing=true

  - See [Enable apiserver flags](https://kubernetes.io/docs/tasks/access-kubernetes-api/configure-aggregation-layer/)

#### 2. Restart kube-apiserver

    systemctl restart kube-apiserver

#### 3. Create Metrics Server
- ##### Get files

      git clone https://github.com/kubernetes-incubator/metrics-server
      cd metrics-server
      kubectl create -f deploy/1.8+/

  - 注意可能需要修改 `metrics-server-deployment.yaml` 中 image 
    - image: gcr.io/google_containers/metrics-server-amd64:v0.2.1
      - image: statemood/metrics-server-amd64:v0.2.1

- ##### Check Status

      kubectl -n kube-system get pods -l k8s-app=metrics-server


#### 4. Create HPA
##### By yaml
- hpa.yaml

      apiVersion: autoscaling/v1
      kind: HorizontalPodAutoscaler
      metadata:
        name: hpa-demo-service
        labels:
          app: demo-service
          label: hpa
      spec:
        scaleTargetRef:
          apiVersion: v1
          kind: Deployment
          name: demo-service
        minReplicas: 1
        maxReplicas: 10
        targetCPUUtilizationPercentage: 30


- deployment.yaml

      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: demo-service
        labels:
          label: hpa
      spec:
        replicas: 1
        selector:
          matchLabels:
            app: demo-service
            label: hpa
        template:
          metadata:
            labels:
              label: hpa
              app: demo-service
          spec:
            containers:
            - name: demo-service
              image: demo-image
              imagePullPolicy: Always
              securityContext:
                runAsUser:  1000
                privileged: true
              ports:
              - containerPort: 8080
              resources:
                limits:
                  cpu: 600m
                  memory: 2Gi
                requests:
                  cpu: 300m
                  memory: 1Gi

  - **resources.request** 必须设置

##### By Command
- `kubectl create hpa deploy demo-service --cpu-percent=50 --min=3 --max=10`

#### 5. Test
- CPU 压力测试

      time echo "scale=5000;4*a(1)" | bc -l -q

#### 6. Command Lines
- 查看HPA状态
  - `kubectl get hpa`

## 参考文档

1. [feiskyer/kubernetes-handbook/Metrics](https://github.com/feiskyer/kubernetes-handbook/blob/master/zh/addons/metrics.md)
2. [Configure the aggregation layer](https://kubernetes.io/docs/tasks/access-kubernetes-api/configure-aggregation-layer/)
