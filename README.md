# cdrdemo
Stream and process Change Data Records (CDR's) using Confluent Platform.
This demo system generates dummy CDR data which is ingested using Kafka Connect into a topic.
It is designed to run on a mac with these clients installed:
* Google Cloud platform ("gcloud")
* Confluent Cloud ("ccloud")
* Confluent Platform
* Kubernetes (kubectl/helm)

Before running, these logins must be configured:
* gcloud: run "gcloud login" to initialize a gcloud session
* ccloud: Follow the steps to create a Ccloud cli configuration file (~/.ccloud/config)

A docker repository login is required for the customized docker images.

The topic messages are filtered and aggregated using kSQL, with schema registration.

The Kafka Brokers are Confluent Cloud.
The schema registry is Confluent Cloud Schema Registry
Kafka Connect runs on Confluent Operator on Google GKE.
kSQL runs on Confluent Operator on Google GKE.

The demo is designed to be run repeatedly, with configuration changes between each run to measure the impact on performance.
It creates the GKE cluster and Confluent Operator cluster for each invocation, and deletes them as the final step of each demo run.
Confluent Cloud connectivity is required, and the topic is created, loaded and then dropped for each demo run.

Extensive log information is extracted for each run in a local dirtectory: ../cdrdemo_run. Edit cdrdemo_runme to change this directory.


To run the demo, change directory to the location of the script "cdrdemo_runme" and run it:
./cdrdemo_runme



         ****************************
         *       CDR Demo           *
         ****************************

1. Set CDRs per file [ 50000 ]
2. Set number of files [ 300 ]
3. Toggle Producer Compression [ none ]
4. Set linger.ms [ 2000 ]
5. Set  batch.size [ 16384 ]
6. Rebuild Docker image [ stale ]
7. Run CDR Load
8. Regenerate Confluent Cloud config files

Enter an Option:


Menu options:
1 "Set CDRs per file" - the number of CDR lines in each CDR data file. CDR data files are created automatically in /var/tmp/queued on the Connect worker pods. Each CDR lines is comma dellimited with 81 attributes. Some are randmonized, most are repeated strings. Each file is processed by one Kafka Connect task so adjust the file size when tuning various batch size configurations for spooldir.

2 "Set number of files" to set the number of files in /var/tmp/queued. Increasing the number of files extends the duration of each demo run.

3 "Toggle Producer Compression" to change the Kafka Connect producer compression algorithm - one of none, zstd, snappy or gzip.

4 Set linger.ms to change the Kafka Connect producer session linger milliseconds

5. Set batch.size to change the Kafka Connect producer batch.size

6. "Rebuild Docker Image" to create a new custom docker image for Kafka Connect, which will be used for the next demo run. This must be done before the first run. The docker container version number will be incremente each time this is selected.

7. RUn CDR Load to execute the demo. It typicaally takes 30-60 mins per run. The logged in session should be active and in the foreground .

8. Regenerate Confluent Cloud config files recreates the configuration files in ~{WORKDIR}/cloud_delta after re-reading ~/ccloud/.config. This is run automatically each time the menu is re-run.

