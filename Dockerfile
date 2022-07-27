
FROM maven:3.8.6-jdk-11 AS BUILD
RUN mkdir /build

COPY src /build/src
COPY pom.xml /build
#COPY mvnw /build
#COPY .mvn/ /build/

#RUN ls -l /build/

WORKDIR /build

RUN mvn package -DskipTests

FROM openjdk:buster
ARG DT_TENANT
COPY --from=zhy38306.live.dynatrace.com/linux/oneagent-codemodules:java / /
ENV LD_PRELOAD /opt/dynatrace/oneagent/agent/lib64/liboneagentproc.so

RUN mkdir /app
COPY --from=BUILD /build/target/rest-service-0.0.1-SNAPSHOT.jar /app/app.jar

WORKDIR /app

ENTRYPOINT [ "java", "-jar", "app.jar" ]
