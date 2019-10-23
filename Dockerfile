FROM openjdk:8-alpine3.8

ENV livy_version="0.6.0-incubating"
ENV spark_version="2.4.4"
ENV hadoop_version="2.9.2"
ARG release

LABEL com.actionml.spark.vendor=ActionML \
      com.actionml.livy.version=$livy_version \
      com.actionml.spark.version=$spark_version \
      com.actionml.livy.release=$release

ENV LIVY_HOME=/livy
ENV SPARK_HOME=/spark
ENV HADOOP_HOME=/hadoop
ENV HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop

RUN adduser -Ds /bin/bash -h ${LIVY_HOME} livy && \
    apk add --no-cache bash tini libc6-compat linux-pam krb5 krb5-libs curl gnupg unzip python3

# LIVY
RUN file=apache-livy-${livy_version}-bin.zip ; \
		curl https://www.apache.org/dist/incubator/livy/${livy_version}/${file} >> ${file}; \
		curl https://www.apache.org/dist/incubator/livy/${livy_version}/${file}.sha512 >> ${file}.sha512 ; \
	  sha512sum ${file} && \
		unzip ${file} ; \
		mv apache-livy-${livy_version}-bin/* ${LIVY_HOME} && \
		mkdir -p ${LIVY_HOME}/logs; chown -R livy:livy ${LIVY_HOME} && \
		mkdir /logs; chown livy:livy /logs

# SPARK
RUN cd /tmp && export GNUPGHOME=/tmp && \
    file=spark-${spark_version}-bin-hadoop2.7.tgz && \
    curl --remote-name-all -w "%{url_effective} fetched\n" -sSL \
        https://archive.apache.org/dist/spark/spark-${spark_version}/{${file},${file}.sha512} && \
	  sha512sum ${file} && \
# create spark directories
    mkdir -p ${SPARK_HOME}/work ${SPARK_HOME}/conf; chown -R livy:livy ${SPARK_HOME} && \
    tar -xzf ${file} --no-same-owner --strip-components 1 && \
    mv * ${SPARK_HOME}

# python 3
RUN ln -s /usr/bin/python3 /usr/bin/python

# HADOOP
RUN mkdir ${HADOOP_HOME}
RUN chown livy:livy ${HADOOP_HOME}
RUN cd /tmp && export GNUPGHOME=/tmp && \
    file=hadoop-${hadoop_version}.tar.gz && \
    curl --remote-name-all -w "%{url_effective} fetched\n" -sSL \
    https://archive.apache.org/dist/hadoop/core/hadoop-2.9.2/{${file},${file}.sha512} && \
	  sha512sum ${file} && \
    tar -xzf ${file} --no-same-owner --strip-components 1 && \
    mv * ${HADOOP_HOME}


COPY entrypoint.sh /
COPY livy.conf ${LIVY_HOME}/conf
COPY log4j.properties ${LIVY_HOME}/conf
COPY spark-blacklist.conf ${LIVY_HOME}/conf

WORKDIR ${LIVY_HOME}/bin
ENTRYPOINT [ "/entrypoint.sh" ]

# Specify the User that the actual main process will run as
USER livy:livy
