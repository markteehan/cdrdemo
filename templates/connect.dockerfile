FROM confluentinc/cp-server-connect-operator:5.3.0.0
RUN mkdir -p /usr/share/java /usr/share/confluent-hub-components
RUN mkdir /var/tmp/queued /var/tmp/processed /var/tmp/error
RUN chmod 777 -R /var/tmp/queued /var/tmp/processed /var/tmp/error
ENV CONNECT_PLUGIN_PATH="/usr/share/java,/usr/share/confluent-hub-components"

RUN sed --in-place=BAK '76inohup \/var\/tmp\/genSpoolFiles.sh & ' /opt/caas/bin/configure

#RUN sed --in-place=BAK '76iecho producer.compression.type=\"REPLACEME_PRODUCER_COMPRESSION_TYPE\" >> /opt/confluent/etc/connect/connect.properties' /opt/caas/bin/configure
#RUN sed --in-place=BAK '76iecho buffer.memory=REPLACEME_BUFFER_MEMORY >> /opt/confluent/etc/connect/connect.properties' /opt/caas/bin/configure
#RUN sed --in-place=BAK '76iecho linger.ms=REPLACEME_LINGER_MS >> /opt/confluent/etc/connect/connect.properties' /opt/caas/bin/configure
#RUN sed --in-place=BAK '76iecho send.buffer.bytes=264400 >> /opt/confluent/etc/connect/connect.properties' /opt/caas/bin/configure
RUN sed --in-place=BAK '76iecho group.id=`hostname` >> /opt/confluent/etc/connect/connect.properties' /opt/caas/bin/configure

#modify the topic names so that connect nodes dont share topics. One trio of topics per connector node.
RUN sed --in-place=BAK '76iecho offset.storage.topic=\"democluster-`hostname`-offset\" >> /opt/confluent/etc/connect/connect.properties' /opt/caas/bin/configure
RUN sed --in-place=BAK '76iecho config.storage.topic=\"democluster-`hostname`-config\" >> /opt/confluent/etc/connect/connect.properties' /opt/caas/bin/configure
RUN sed --in-place=BAK '76iecho status.storage.topic=\"democluster-`hostname`-status\" >> /opt/confluent/etc/connect/connect.properties' /opt/caas/bin/configure
RUN sed --in-place=BAK '76icat /var/tmp/ccloud.properties                                                        >> /opt/confluent/etc/connect/connect.properties' /opt/caas/bin/configure
RUN sed --in-place=BAK '76i cat /opt/confluent/etc/connect/connect.properties' /opt/caas/bin/configure
RUN sed --in-place=BAK '76i cp /opt/confluent/etc/connect/connect.properties /var/tmp' /opt/caas/bin/configure
RUN sed --in-place=BAK '76i cp /var/tmp/admin.properties /opt/confluent/etc/connect/admin.properties' /opt/caas/bin/configure

RUN confluent-hub install --no-prompt jcustenborder/kafka-connect-spooldir:latest
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-replicator:5.3.1

#
# overwrite confluent-hub spooldir with Spooldir 2.0 to enable tasks=n and to fix bugs
COPY files/jcustenborder-kafka-connect-spooldir-2.0.tar /usr/share/confluent-hub-components/jcustenborder-kafka-connect-spooldir/jcustenborder-kafka-connect-spooldir-2.0.tar
RUN cd /usr/share/confluent-hub-components/jcustenborder-kafka-connect-spooldir && tar xvf jcustenborder-kafka-connect-spooldir-2.0.tar
RUN rm /usr/share/confluent-hub-components/jcustenborder-kafka-connect-spooldir/jcustenborder-kafka-connect-spooldir-2.0.tar
RUN touch /usr/share/confluent-hub-components/jcustenborder-kafka-connect-spooldir/OVERWRITTEN_WITH_SPOOLDIR_2
RUN touch /var/tmp/jcustenborder-kafka-connect-spooldir_OVERWRITTEN_WITH_SPOOLDIR_2
#
#
ADD REPLACEME_GENSPOOLFILE /var/tmp/genSpoolFiles.sh
ADD REPLACEME_CCLOUD_PROPERTIES /var/tmp/ccloud.properties
ADD REPLACEME_ADMIN_PROPERTIES /var/tmp/admin.properties
RUN chmod a+r /var/tmp/ccloud.properties
