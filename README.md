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


```
When you run it, this is what happens:  
       setLogLocation - write logfiles to a destination directory
            setBroker - the only broker option now is Confluent Cloud. We can add Operator later; and Apache Kafka.
       destroyCluster - tear down the GKE cluster; in case the prior run didnt complete successfully.
       deleteCCTopics - connect - delete Kafka Connect topics from the brokers. Fresh topics are used for each demo run.
       deleteCCTopics - CDR - delete the CDR topic(s) to avoid billable data accumulation on Confluent Cloud between runs
       deleteCCTopics - _confluent-ksql - re-initialize any streams/tables in kSQL. 
          makeCluster - build the GKE cluster and the Operator cluster.
 recreatePortForwards - Recreate port forwards ("kubectl forward") for ssh/logs cmds to the demo pods
    deleteConnectJobs - delete any Kafka Connect jobs that may remain after failed runs.
          createTopic - create a new topic for the CDR data
  streamConnectLogFileMultiplexed - kubectl tail -f the stdio for all connect pods to one file for easier grepping
     startConnectJobs - start five Kafka Connect jobs on each Worker - so for ten workers, this will start 50 jobs
          #createKsql - currently commented out
        checkTestData - Check each worker pod and count how many files are queued/finished/errored
  getConnectRowsProcessed - summarize the run by grepping the logfile
       getPodLogfiles - download logfiles from the pods before they are destroyed  destroyCluster
 



To run the demo, change directory to the location of the script "cdrdemo_runme" and run it:
./cdrdemo_runme


         ****************************
         *       CDR Demo           *
         ****************************


Demo:                             Configure:
 1.       Run All Steps           c1. CDRs per file [ 50000 ]
 2.       Auto-Destroy [Y]        c2. Number of files [ 300 ]
 3.       exit                    c3. Producer Compression [ none ]
                                  c4. linger.ms [ 2000 ]
Demo Steps:                       c5. batch.size [ 16384 ]
GKE:
s1       destroyCluster
s2          makeCluster
s3 recreatePortForwards           Docker:
s4       getPodLogfiles           d1. Rebuild custom docker Images [ stale ]

Confluent:
s5         deleteTopics
s6          createTopic
s7             dropKSQL
s8           createKSQL

Kafka Connect:
s9    deleteConnectJobs
s10    startConnectJobs

Enter an Option:
Menu options:
1. "Run all steps" - run a demo, end to end with no pauses
2. "Auto Destroy" - tear down cluster at the end of the demo
x. exit (or Control-C)

s1-s10 - run/repeat demo steps manually


c1 "Set CDRs per file" - the number of CDR lines in each CDR data file. CDR data files are created automatically in /var/tmp/queued on the Connect worker pods. Each CDR lines is comma dellimited with 81 attributes. Some are randmonized, most are repeated strings. Each file is processed by one Kafka Connect task so adjust the file size when tuning various batch size configurations for spooldir.

c2 "Set number of files" to set the number of files in /var/tmp/queued. Increasing the number of files extends the duration of each demo run.

c3 "Toggle Producer Compression" to change the Kafka Connect producer compression algorithm - one of none, zstd, snappy or gzip.

c4 Set linger.ms to change the Kafka Connect producer session linger milliseconds

c5 Set batch.size to change the Kafka Connect producer batch.size

c6 "Rebuild Docker Image" to create a new custom docker image for Kafka Connect, which will be used for the next demo run. This must be done before the first run. The docker container version number will be incremente each time this is selected.

c7 "Run CDR Load" to execute the demo. It typically takes 30-60 mins per run. The logged in session should be active and in the foreground while the demo is running.


