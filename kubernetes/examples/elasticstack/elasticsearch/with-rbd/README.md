# Elasticsearch Cluster

#### Version: 6.2.2

#### Based from https://github.com/pires/kubernetes-elasticsearch-cluster


## Nodes

| ROLE    | PORT          | DATA  |
| -       | :-:           | :-:   |
| Client  | 9200<br>9300  | No    |
| Master  | 9300          | No    |
| Data    | 9300          | YES   |

## Start Cluster

#### 1. Create Service Account

    kubectl create -f es-service-account.yaml

#### 2. Create Discovery Service

    kubectl create -f es-discovery-svc.yaml

#### 3. Create Service

    kubectl create -f es-service.yaml

#### 4. Create Master node

    kubectl create -f es-master.yaml

  - Wait until the pod to be ready

#### 5. Create Client node

    kubectl create -f es-client.yaml

#### 6. Create Data node

    kubectl create -f es-data.yaml

## Scale Up Cluster
#### 1. Scale up master node to 2

    kubectl scale --replicas=2 statefulset/es-master -n NAMESPACE

#### 2. Scale up client node to 2

    kubectl scale --replicas=2 statefulset/es-client -n NAMESPACE

#### 3. Scale up data node to 5

    kubectl scale --replicas=5 statefulset/es-data -n NAMESPACE
