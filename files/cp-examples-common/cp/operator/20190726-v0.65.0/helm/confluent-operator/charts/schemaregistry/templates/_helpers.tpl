{{/*
Configure JVM configuration for SchemaRegistry.
*/}}
{{- define "schemaregistry.jvm-config" }}

-Xmx {{- $.Values.jvmConfig.heapSize }}
-Xms {{- $.Values.jvmConfig.heapSize }}
-XX:+UnlockExperimentalVMOptions
-XX:+UseCGroupMemoryLimitForHeap
-server
-XX:MetaspaceSize=96m
-XX:+UseG1GC
-XX:MaxGCPauseMillis=20
-XX:InitiatingHeapOccupancyPercent=35
-XX:+ExplicitGCInvokesConcurrent
-XX:G1HeapRegionSize=16
-XX:MinMetaspaceFreeRatio=50
-XX:MaxMetaspaceFreeRatio=80
-Djava.awt.headless=true

-XX:ParallelGCThreads=1
-XX:ConcGCThreads=1

-Dcom.sun.management.jmxremote=true
-Dcom.sun.management.jmxremote.authenticate=false
-Dcom.sun.management.jmxremote.ssl=false
-Dcom.sun.management.jmxremote.local.only=false
-Dcom.sun.management.jmxremote.rmi.port=7203
-Dcom.sun.management.jmxremote.port=7203

-XX:+PrintFlagsFinal
-XX:+UnlockDiagnosticVMOptions

{{- end }}

{{- define "schemaregistry.kafka-config" }}
{{- $protocol :=  (include "confluent-operator.kafka-external-advertise-protocol" .) | trim  }}
{{- $bootstrap :=  .Values.dependencies.kafka.bootstrapEndpoint }}
{{- if contains "SASL" $protocol }}
{{  printf "kafkastore.bootstrap.servers=%s://%s" $protocol $bootstrap }}
{{- else }}
{{- if contains "2WAYSSL" $protocol }}
{{ printf "kafkastore.bootstrap.servers=SSL://%s" $bootstrap }}
{{ else }}
{{ printf "kafkastore.bootstrap.servers=%s://%s" $protocol $bootstrap }}
{{- end }}
{{- end }}
{{- range $i, $val := splitList "\n" ( include "confluent-operator.kafka-client-security" . | trim ) }}
{{- if not (empty $val) }}
{{ printf "kafkastore.%s" $val }} 
{{- end }}
{{- end }}
{{- end }}