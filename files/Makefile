# Imported environment variables
#
# BS
THIS_MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
THIS_MKFILE_DIR := $(dir $(THIS_MKFILE_PATH))
include $(THIS_MKFILE_DIR)/cp-examples-common/Makefile
GCP_PROJECT_ID ?= $(shell gcloud config list --format 'value(core.project)')

GCP_PROJECT_ID ?= $(shell gcloud config list --format 'value(core.project)')

GKE_BASE_CLUSTER_ID ?= cp-examples-operator-$(USER)
GKE_BASE_REGION ?= asia-southeast1
GKE_BASE_ZONE ?= asia-southeast1-a
GKE_BASE_SUBNET ?= default
GKE_BASE_CLUSTER_VERSION ?= 1.14.7
GKE_BASE_MACHINE_TYPE ?= n1-highmem-4
GKE_BASE_IMAGE_TYPE ?= COS
GKE_BASE_DISK_TYPE ?= pd-standard
GKE_BASE_DISK_SIZE ?= 100
GKE_BASE_NUM_NODES ?= 11

GKE_BASE_ZOOKEEPER_REPLICAS ?= 1
GKE_BASE_KAFKA_REPLICAS ?= 3
GKE_BASE_CONNECT_REPLICAS ?= 1
GKE_BASE_SCHEMA_REGISTRY_REPLICAS ?= 1

KUBECTL_CONTEXT ?= gke_$(GCP_PROJECT_ID)_$(GKE_BASE_ZONE)_$(GKE_BASE_CLUSTER_ID)
KUBECTL_NAMESPACE=democluster

gke-kubectl-current-context = $(shell kubectl config current-context 2>&1 /dev/null)

#HELM_COMMON_FLAGS := --set global.provider.registry.fqdn=docker.io --set global.provider.name=gcp --set global.provider.region=$(GKE_BASE_REGION) --set global.provider.kubernetes.deployment.zones={$(GKE_BASE_ZONE)} --set global.provider.storage.provisioner=kubernetes.io/gce-pd --set global.provider.storage.reclaimPolicy=Delete --set global.provider.storage.parameters.type=pd-ssd --set global.provider.sasl.plain.username=test --set global.provider.sasl.plain.password=test123
HELM_COMMON_FLAGS := --set global.provider.registry.fqdn=docker.io --set global.provider.name=gcp --set global.provider.region=$(GKE_BASE_REGION) --set global.provider.kubernetes.deployment.zones={$(GKE_BASE_ZONE)} --set global.provider.storage.provisioner=kubernetes.io/gce-pd --set global.provider.storage.reclaimPolicy=Delete --set global.provider.storage.parameters.type=pd-ssd

gke-check-dependencies: check-dependencies
	@$(call check-var-defined,GCP_PROJECT_ID)
	@$(call check-dependency,gcloud)
	@$(call echo_pass,gke-base dependencies verified)

gke-create-cluster: gke-check-dependencies ## Creates a GKE cluster based on the values of the GKE_* variables.  WARN: This will incur charges in your GCP account.
	@$(call echo_stdout_header,Create GKE cluster expect 4 mins)	
	gcloud --quiet container --project $(GCP_PROJECT_ID) clusters create $(GKE_BASE_CLUSTER_ID) --zone $(GKE_BASE_ZONE) --no-enable-basic-auth --cluster-version $(GKE_BASE_CLUSTER_VERSION) --machine-type $(GKE_BASE_MACHINE_TYPE) --image-type $(GKE_BASE_IMAGE_TYPE) --disk-type $(GKE_BASE_DISK_TYPE) --disk-size $(GKE_BASE_DISK_SIZE) --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --num-nodes $(GKE_BASE_NUM_NODES) --enable-cloud-logging --enable-cloud-monitoring --enable-ip-alias --network "projects/$(GCP_PROJECT_ID)/global/networks/default" --subnetwork "projects/$(GCP_PROJECT_ID)/regions/$(GKE_BASE_REGION)/subnetworks/$(GKE_BASE_SUBNET)" --default-max-pods-per-node "110" --addons HorizontalPodAutoscaling,HttpLoadBalancing --enable-autoupgrade --enable-autorepair
	@$(call echo_stdout_footer_pass,GKE Cluster Created)

gke-destroy-cluster: gke-check-dependencies ## Destroys the GKE cluster built from the gke-create-cluster command 
	@$(call echo_stdout_header,Delete GKE cluster)
	gcloud --quiet container clusters delete $(GKE_BASE_CLUSTER_ID) --zone $(GKE_BASE_ZONE)
	@$(call echo_stdout_footer_pass,GKE Cluster Deleted)

gke-base-validate: gke-check-dependencies init
	@echo
	@$(call echo_pass,gke-base demo validation complete)

###### OPERATOR MANAGEMENT ######
gke-base-deploy-operator: #_ Deploys the Confluent Operator into the configured k8s cluster 
	@$(call echo_stdout_header,deploy $(KUBECTL_NAMESPACE))	
	helm upgrade --install --namespace $(KUBECTL_NAMESPACE) --set operator.enabled=true $(HELM_COMMON_FLAGS) $(KUBECTL_NAMESPACE) $(OPERATOR_PATH)helm/confluent-operator
	@$(call echo_stdout_footer_pass,operator deployed)

gke-base-wait-for-operator: #_ Waits until the Confluent Operator rollout status is complete
	@$(call echo_stdout_header,wait for operator)	
	kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) rollout status deployment/cc-operator
	kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) rollout status deployment/cc-manager
	@$(call echo_stdout_footer_pass,operator ready)

gke-base-destroy-operator: #_ Destroy the operator deployment on the configured k8s cluster
	@$(call echo_stdout_header,destroy operator)
	-helm delete --purge operator
	@$(call echo_stdout_footer_pass,operator destroyed)

gke-base-wait-for-operator-destruction: #j Will wait until the Confluent Operator & Manager are destroyed
	@$(call echo_stdout_header,ensure operator destroyed)
	-kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) wait --timeout=60s --for=delete deployment/cc-manager
	-kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) wait --timeout=60s --for=delete deployment/cc-operator
	@$(call echo_stdout_footer_pass,operator gone)
#################################

###### ZOOKEEPER MANAGEMENT ######
gke-base-deploy-zookeeper: #_ Deploys Zookeeper into the configured k8s cluster
	@$(call echo_stdout_header,Deploy Zookeeper)
	helm upgrade --install --namespace $(KUBECTL_NAMESPACE) --set zookeeper.enabled=true --set zookeeper.resources.cpu=200m --set zookeeper.resources.memory=512Mi --set zookeeper.replicas=$(GKE_BASE_ZOOKEEPER_REPLICAS) $(HELM_COMMON_FLAGS) zookeeper $(OPERATOR_PATH)helm/confluent-operator
	@$(call echo_stdout_footer_pass,Zookeeper deployed)

gke-base-wait-for-zookeeper: #_ Waits until the Zookeeper rollout is complete
	@$(call echo_stdout_header,Wait for Zookeper)
	source $(COMMON_MKFILE_DIR)bin/retry.sh; retry 15 kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) get sts zookeeper 
	kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) rollout status statefulset/zookeeper
	@$(call echo_stdout_footer_pass,Zookeeper ready)

gke-base-destroy-zookeeper: #_ Purge the Zookeeper package 
	@$(call echo_stdout_header,Purge the Zookeeper package)
	-helm delete --purge zookeeper
# There are currently some issues with ZK cleanup in the Helm packages, for now i'm helping along with extra delete commands
	-kubectl -n $(KUBECTL_NAMESPACE) delete sts/zookeeper
	-kubectl -n $(KUBECTL_NAMESPACE) delete service/zookeeper;kubectl -n $(KUBECTL_NAMESPACE) delete service/zookeeper-0-internal;
	@$(call echo_stdout_footer_pass,Zookeeper purged)

gke-base-wait-for-zookeeper-destruction: #_ Waits until the Zookeper cluster is destroyed
	@$(call echo_stdout_header,Ensure Zookeeper destroyed)
	-kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) wait --timeout=60s --for=delete statefulset/zookeeper
	@$(call echo_stdout_footer_pass,Zookeeper gone)
#################################

######### KAFKA MANAGEMENT ######
gke-base-deploy-kafka: #_ Deploys Kafka into the configured k8s cluster
	@$(call echo_stdout_header,deploy kafka) 
	helm upgrade --install --namespace $(KUBECTL_NAMESPACE) --set kafka.image.repository=confluentinc/cp-server-operator --set kafka.image.tag=5.3.1.0 --set kafka.enabled=true --set kafka.resources.cpu=200m --set kafka.resources.memory=4Gi --set kafka.volume.data0=50Gi --set kafka.loadBalancer.enabled=false --set kafka.tls.enabled=false --set kafka.metricReporter.enabled=true --set kafka.configOverrides.server={"auto.create.topics.enable=true"} --set kafka.replicas=$(GKE_BASE_KAFKA_REPLICAS) $(HELM_COMMON_FLAGS) kafka $(OPERATOR_PATH)helm/confluent-operator
	@$(call echo_stdout_footer_pass,Kafka deployed)

gke-base-wait-for-kafka: #_ Waits until the Kafka rollout is complete
	@$(call echo_stdout_header,Wait for Kafka)
	source $(COMMON_MKFILE_DIR)bin/retry.sh; retry 15 kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) get sts kafka 
	kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) rollout status statefulset/kafka
	@$(call echo_stdout_footer_pass,Kafka ready)

gke-base-destroy-kafka: #_ Purge the Kafka package 
	@$(call echo_stdout_header,Purge the Kafka package)
	-helm delete --purge kafka 
	@$(call echo_stdout_footer_pass,Kafka purged)

gke-base-wait-for-kafka-destruction: #_ Waits until the Kafka cluster is destroyed
	@$(call echo_stdout_header,Ensure Kafka destroyed)
	-kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) wait --timeout=60s --for=delete statefulset/kafka
	@$(call echo_stdout_footer_pass,Kafka gone)
#################################

### SCHEMA REGISTRY MANAGEMENT ##
gke-base-deploy-schemaregistry: #_ Deploys the Schmea Registry to the configured k8s cluster
	@$(call echo_stdout_header,Deploy Schema Registry)
	helm upgrade --install --namespace $(KUBECTL_NAMESPACE) --set schemaregistry.enabled=true --set schemaregistry.dependencies.kafka.brokerCount=3 --set schemaregistry.dependencies.kafka.bootstrapEndpoint=${BS} --set schemaregistry.replicas=$(GKE_BASE_SCHEMA_REGISTRY_REPLICAS) $(HELM_COMMON_FLAGS) schemaregistry $(OPERATOR_PATH)helm/confluent-operator
	@$(call echo_stdout_footer_pass,Schema Registry deployed)

gke-base-wait-for-schemaregistry: #_ Waits until the Schema Registry rollout is complete
	@$(call echo_stdout_header,Wait for Schema Registry)
	source $(COMMON_MKFILE_DIR)bin/retry.sh; retry 15 kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) get sts schemaregistry
	kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) rollout status statefulset/schemaregistry
	@$(call echo_stdout_footer_pass,Schema Registry ready)

gke-base-destroy-schemaregistry: #_ Purge the Schema Registry package
	@$(call echo_stdout_header,Purge the Schema Registry package)
	-helm delete --purge schemaregistry 
	@$(call echo_stdout_footer_pass,Schema Registry purged) 

gke-base-wait-for-schemaregistry-destruction: #_ Waits until the Schema Registry is destroyed
	@$(call echo_stdout_header,Ensure Schema Registry destroyed)
	-kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) wait --timeout=60s --for=delete statefulset/schemaregistry
	@$(call echo_stdout_footer_pass,Schema Registry gone)
#################################

##### CONNECT  MANAGEMENT #######
gke-base-deploy-connect: #_ Deploys Kafka Connect to the configured k8s cluster
	@$(call echo_stdout_header,Deploy Kafka Connect)

	helm upgrade --install --namespace $(KUBECTL_NAMESPACE) --set connect.enabled=true --set connect.image.repository=${P_GITHUB_REPO}/cp-kafka-connect-telcodemo-spooldir --set connect.image.tag=${DOCKER_REL} --set connect.dependencies.kafka.tls.enabled="true" --set connect.dependencies.kafka.tls.authentication.type="plain"  --set connect.loadBalancer.enabled=false --set connect.dependencies.kafka.brokerCount=3 --set connect.dependencies.kafka.bootstrapEndpoint=${BS} --set connect.dependencies.schemaregistry.enabled=true --set connect.replicas=$(GKE_BASE_CONNECT_REPLICAS) $(HELM_COMMON_FLAGS) connect $(OPERATOR_PATH)helm/confluent-operator
	@$(call echo_stdout_footer_pass,Kafka Connect deployed)

gke-base-wait-for-connect: #_ Waits until the Kafka Connect rollout is complete
	@$(call echo_stdout_header,Wait for Kafka Connect)
	source $(COMMON_MKFILE_DIR)bin/retry.sh; retry 15 kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) get sts connectors
	kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) rollout status statefulset/connectors
	@$(call echo_stdout_footer_pass,Kafka Connect ready)

gke-base-destroy-connect: #_ Purge the Kafka Connect package 
	@$(call echo_stdout_header,Purge the Kafka Connect package)
	-helm delete --purge connect 
	@$(call echo_stdout_footer_pass,Kafka Connect purged)

gke-base-wait-for-connect-destruction: #_ Waits until Kafka Connect is destroyed
	@$(call echo_stdout_header,Ensure Kafka Connect destroyed)
	-kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) wait --timeout=60s --for=delete statefulset/connectors
	@$(call echo_stdout_footer_pass,Kafka Connect gone)
#################################


gke-base-deploy-ksql: #_ Deploys kSQL to the configured k8s cluster
	@$(call echo_stdout_header,Deploy kSQL)
	helm upgrade --install --namespace $(KUBECTL_NAMESPACE) --set ksql.image.repository=${GITHUB_REPO}/cp-kafka-ksql-telcodemo-spooldir --set ksql.image.tag=${DOCKER_REL} --set ksql.enabled=true --set ksql.tls.enabled=false --set ksql.loadBalancer.enabled=false --set ksql.dependencies.kafka.brokerCount=3 --set ksql.dependencies.kafka.bootstrapEndpoint=${BS} --set ksql.dependencies.kafka.brokerEndpoints=${BS} --set ksql.dependencies.schemaRegistry.enabled=true --set ksql.dependencies.schemaRegistry.url=http://schemaregistry:8081  --set ksql.replicas=$(GKE_BASE_KSQL_REPLICAS) $(HELM_COMMON_FLAGS) ksql $(OPERATOR_PATH)helm/confluent-operator
	@$(call echo_stdout_footer_pass,KSQL deployed)

gke-base-wait-for-ksql: #_ Waits until the kSQL rollout is complete
	@$(call echo_stdout_header,Wait for kSQL)
	source $(COMMON_MKFILE_DIR)bin/retry.sh; retry 15 kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) get sts ksql
	kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) rollout status statefulset/ksql
	@$(call echo_stdout_footer_pass,kSQL ready)

gke-base-destroy-ksql: #_ Purge the kSQL package 
	@$(call echo_stdout_header,Purge the kSQL package)
	-helm delete --purge ksql 
	@$(call echo_stdout_footer_pass,kSQL purged)

gke-base-wait-for-ksql-destruction: #_ Waits until kSQL is destroyed
	@$(call echo_stdout_header,Ensure kSQL destroyed)
	-kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) wait --timeout=60s --for=delete statefulset/ksql
	@$(call echo_stdout_footer_pass,kSQL gone)
#################################

### CONTROL CENTER MANAGEMENT ####
gke-base-deploy-controlcenter: #_ Deploys Confluent Control Center to the configured k8s cluster
	@$(call echo_stdout_header,Deploy Control Center)
	helm upgrade --install --namespace $(KUBECTL_NAMESPACE) --set controlcenter.enabled=true --set controlcenter.dependencies.c3KafkaCluster.zookeeper.endpoint=zookeeper:2181 --set controlcenter.dependencies.c3KafkaCluster.bootstrapEndpoint=${BS} --set controlcenter.dependencies.c3KafkaCluster.brokerCount=3 --set controlcenter.dependencies.connectCluster.enabled=true --set controlcenter.dependencies.connectCluster.url=http://connectors:8083 --set controlcenter.dependencies.schemaRegistry.enabled=true --set controlcenter.dependencies.schemaRegistry.url=http://schemaregistry:8081 $(HELM_COMMON_FLAGS) --set controlcenter.dependencies.ksql.enabled=true --set controlcenter.dependencies.ksql.url=http://ksql:8088 controlcenter --set controlcenter.dependencies.ksql.schemaRegistry.url=http://schemaregistry:8081 $(OPERATOR_PATH)helm/confluent-operator
	@$(call echo_stdout_footer_pass,Control Center deployed)

gke-base-wait-for-controlcenter: #_ Waits until the Control Center rollout is complete
	@$(call echo_stdout_header,Wait for Control Center)
	source $(COMMON_MKFILE_DIR)bin/retry.sh; retry 15 kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) get sts controlcenter 
	kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) rollout status statefulset/controlcenter
	@$(call echo_stdout_footer_pass,Control Center ready)

gke-base-destroy-controlcenter: #_ Purge the Control Center package 
	@$(call echo_stdout_header,Purge the Control Center package)
	-helm delete --purge controlcenter 
	@$(call echo_stdout_footer_pass,Control Center purged)

gke-base-wait-for-controlcenter-destruction: #_ Waits until Control Center is destroyed
	@$(call echo_stdout_header,Ensure Control Center destroyed)
	-kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) wait --timeout=60s --for=delete statefulset/controlcenter
	@$(call echo_stdout_footer_pass,Control Center gone)
#################################

### CLICKS DATA GEN CONNECTOR ###
gke-base-deploy-clicks-connector-config: #_ Deploys configuration for a connector that generates sample click data
	@$(call echo_stdout_header,Deploy clicks datagen connector config)
	kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) apply -f $(THIS_MKFILE_DIR)cfg/clicks-datagen-connector-configmap.yaml
	@$(call echo_stdout_footer_pass,clicks datagen connector config deployed)

gke-base-destroy-clicks-connector-deploy-job: #_ Destroys the job that deployed the sample data generator connector
	@$(call echo_stdout_header,destory Deploy clicks datagen connector job)
	-kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) delete jobs/clicks-datagen-connector-deploy ## name dependnecy in file, required unless/until TTL works across all k8s configurations
	@$(call echo_stdout_footer_pass,clicks datagen connector job destroyed)

gke-base-deploy-clicks-connector: gke-base-deploy-clicks-connector-config gke-base-destroy-clicks-connector-deploy-job #_ Deploys a connector that generates sample click data
	@$(call echo_stdout_header,Deploy clicks datagen connector)
	kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) apply -f $(THIS_MKFILE_DIR)cfg/clicks-datagen-connector-deploy-job.yaml
	@$(call echo_stdout_footer_pass,clicks datagen connector deployed)
#################################

########## CLIENT SECRETS #######
gke-base-deploy-client-secrets:
	@$(call echo_stdout_header,Deploy client secrets)
	kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) apply -f $(THIS_MKFILE_DIR)cfg/kafka-client-secrets.yaml
	@$(call echo_stdout_footer_pass,client secrets deployed)

gke-base-destroy-client-secrets:
	@$(call echo_stdout_header,Delete client secrets)
	-kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) delete secret kafka-client.properties
	@$(call echo_stdout_footer_pass,client secrets destroyed)
#################################

########## CLIENT CONSOLE #######
gke-base-deploy-client-console:
	@$(call echo_stdout_header,Deploy client-console)
	kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) apply -f $(THIS_MKFILE_DIR)cfg/client-console-pod.yaml
	@$(call echo_stdout_footer_pass,client-console deployed)

gke-base-destroy-client-console:
	@$(call echo_stdout_header,Delete client-console)
	-kubectl --context $(KUBECTL_CONTEXT) -n $(KUBECTL_NAMESPACE) delete pod client-console 
	@$(call echo_stdout_footer_pass,client-console destroyed)
#################################

gke-base-demo: gke-base-validate
	@make --no-print-directory gke-base-deploy-operator
	@make --no-print-directory gke-base-wait-for-operator
	@make --no-print-directory gke-base-deploy-zookeeper
	@make --no-print-directory gke-base-wait-for-zookeeper
	@make --no-print-directory gke-base-deploy-kafka
	@make --no-print-directory gke-base-wait-for-kafka
	@make --no-print-directory gke-base-deploy-client-secrets
	@make --no-print-directory gke-base-deploy-client-console
	#@make --no-print-directory gke-base-deploy-schemaregistry
	#@make --no-print-directory gke-base-wait-for-schemaregistry
	@make --no-print-directory gke-base-deploy-connect
	@make --no-print-directory gke-base-wait-for-connect
	#@make --no-print-directory gke-base-deploy-ksql
	#@make --no-print-directory gke-base-wait-for-ksql
	#@make --no-print-directory gke-base-deploy-clicks-connector
	#@make --no-print-directory gke-base-deploy-controlcenter
	#@make --no-print-directory gke-base-wait-for-controlcenter
	@echo
	@$(call echo_pass,GKE Base Demo running)

gke-base-destroy-demo: gke-base-validate
	@make --no-print-directory gke-base-destroy-client-console
	@make --no-print-directory gke-base-destroy-client-secrets
	@make --no-print-directory gke-base-destroy-clicks-connector-deploy-job
	@make --no-print-directory gke-base-destroy-controlcenter
	@make --no-print-directory gke-base-wait-for-controlcenter-destruction
	@make --no-print-directory gke-base-destroy-connect
	@make --no-print-directory gke-base-wait-for-connect-destruction
	@make --no-print-directory gke-base-destroy-schemaregistry
	@make --no-print-directory gke-base-wait-for-schemaregistry-destruction
	@make --no-print-directory gke-base-destroy-ksql
	@make --no-print-directory gke-base-wait-for-ksql-destruction
	@make --no-print-directory gke-base-destroy-kafka
	@make --no-print-directory gke-base-wait-for-kafka-destruction
	@make --no-print-directory gke-base-destroy-zookeeper
	@make --no-print-directory gke-base-wait-for-zookeeper-destruction
	@make --no-print-directory gke-base-destroy-operator
	@make --no-print-directory gke-base-wait-for-operator-destruction
	@echo
	@$(call echo_pass,GKE Base Demo destroyed)

demo: ## Run the base GKE demo, deploys Confluent Platform into current Kubernetes cluster
	@make --no-print-directory gke-base-demo

destroy-demo: ## Destroy the base GKE demo and all Confluent Platform components
	@make --no-print-directory gke-base-destroy-demo

