# Docker image for Liferay DXP on Wildfly (JBoss) based on jboss/wildfly
FROM jboss/wildfly

MAINTAINER Arthur Fayzullin <arthur.fayzullin@gmail.com>

# Environment
ENV LIFERAY_VERSION "7.0.2 GA3"
ENV LIFERAY_VERSION_FULL "7.0-ga3-20160804222206210"
ENV LIFERAY_WAR_SHA1 "3a1a8cd8b5e31c3bdd8c433c6330e8a3cff46251"
ENV LIFERAY_OSGI_SHA1 "f542dcb943cbb5996879b781592ef2545f13b424"
ENV LIFERAY_DEPS_SHA1 "22c0d1bd47c5945bd1a365b0e0bec31885dfd97d"

# Paths
# ENV LIFERAY_HOME /opt/jboss
ENV WILDFLY_STANDALONE_CFG $JBOSS_HOME/standalone/configuration/standalone.xml

# Coping file
COPY files /opt/jboss/files

# USER root

# Installation: liferay-ce-portal
RUN cd $HOME \
    && curl -L -O "http://downloads.sourceforge.net/project/lportal/Liferay Portal/$LIFERAY_VERSION/liferay-ce-portal-$LIFERAY_VERSION_FULL.war" \
    && sha1sum liferay-ce-portal-$LIFERAY_VERSION_FULL.war | grep $LIFERAY_WAR_SHA1 \
    && mkdir -p $JBOSS_HOME/standalone/deployments/ROOT.war \
    && unzip $HOME/liferay-ce-portal-$LIFERAY_VERSION_FULL.war -d $JBOSS_HOME/standalone/deployments/ROOT.war \
    && rm $HOME/liferay-ce-portal-$LIFERAY_VERSION_FULL.war
    # && chown -R jboss:0 $JBOSS_HOME/standalone/deployments/ROOT.war \
    # && chmod -R g+rw $JBOSS_HOME/standalone/deployments/ROOT.war

# Installattion: liferay-ce-portal-osgi
RUN cd $HOME \
    && curl -L -O "http://downloads.sourceforge.net/project/lportal/Liferay Portal/$LIFERAY_VERSION/liferay-ce-portal-osgi-$LIFERAY_VERSION_FULL.zip" \
    && sha1sum liferay-ce-portal-osgi-$LIFERAY_VERSION_FULL.zip | grep $LIFERAY_OSGI_SHA1 \
    && unzip liferay-ce-portal-osgi-$LIFERAY_VERSION_FULL.zip -d $HOME \
    && rm $HOME/liferay-ce-portal-osgi-$LIFERAY_VERSION_FULL.zip \
    && mv $HOME/liferay-ce-portal-osgi* $HOME/osgi
    # && chown -R jboss:0 $LIFERAY_HOME/osgi \
    # && chmod -R g+rw $LIFERAY_HOME/osgi

# Installation: liferay-ce-portal-dependencies
RUN cd $HOME \
    && curl -L -O "http://downloads.sourceforge.net/project/lportal/Liferay Portal/$LIFERAY_VERSION/liferay-ce-portal-dependencies-$LIFERAY_VERSION_FULL.zip" \
    && sha1sum liferay-ce-portal-dependencies-$LIFERAY_VERSION_FULL.zip | grep $LIFERAY_DEPS_SHA1 \
    && mkdir -p $JBOSS_HOME/modules/com/liferay/portal \
    && unzip liferay-ce-portal-dependencies-$LIFERAY_VERSION_FULL.zip -d $JBOSS_HOME/modules/com/liferay/portal \
    && rm liferay-ce-portal-dependencies-$LIFERAY_VERSION_FULL.zip \
    && mv $JBOSS_HOME/modules/com/liferay/portal/liferay-ce-portal-dependencies-* $JBOSS_HOME/modules/com/liferay/portal/main \
    && cp $HOME/files/module.xml $JBOSS_HOME/modules/com/liferay/portal/main/

# Configuration
RUN set -i -e '/<paths/r $HOME/files/standalone-systemmodule.xml' $JBOSS_HOME/modules/system/layers/base/sun/jdk/main/module.xml
RUN sed -i '/org.jboss.as.weld/d' $WILDFLY_STANDALONE_CFG \
    && sed -i -e '/\/extensions/r $HOME/files/standalone-systemproperties.xml' $WILDFLY_STANDALONE_CFG \
    && sed -i 's/<deployment-scanner/<deployment-scanner deployment-timeout="360"/g' $WILDFLY_STANDALONE_CFG \
    && sed -i -e '/<security-domains/r $HOME/files/standalone-securitydomain.xml' $WILDFLY_STANDALONE_CFG \
    && sed -i '/welcome-content/d' $WILDFLY_STANDALONE_CFG \
    && sed -i '/urn:jboss:domain:weld/d' $WILDFLY_STANDALONE_CFG
RUN cat $HOME/files/standalone.conf >> $JBOSS_HOME/bin/standalone.conf

# Cleanup
USER root
RUN rm -rf $HOME/files
USER jboss

# Set the default command to run on boot
# This will boot liferay in the standalone mode and bind to all interface
CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0"]
