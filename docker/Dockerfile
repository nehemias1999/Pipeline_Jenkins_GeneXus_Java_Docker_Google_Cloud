FROM tomcat:10.1.10-jdk21-openjdk-slim

LABEL maintainer="nehemias salazar <nehemiassala@gmail.com>"

WORKDIR /usr/local/tomcat/webapps/

RUN apt-get update && apt -y install zip && rm -rf /ROOT/

COPY ROOT.war .