FROM maven:3.8.4-openjdk-17 AS myapp-build
WORKDIR /app
# Copy the project files into the container
COPY . .
RUN ls -al . && ls -al .m2-cached || echo no .m2-cached/ for now
RUN mvn -Dmaven.repo.local=.m2-cached/ help:effective-settings | tee effective-settings.xml

#dump by executing: docker buildx build --cache-from "mytest:latest" -t mytest:latest -f Dockerfile . --output . --target=myapp-cache
FROM scratch AS myapp-cache
COPY --from=myapp-build /app/.m2-cached /.m2-cached

FROM nginx:1-alpine AS myapp-runtime
WORKDIR /app
COPY --from=myapp-build /app/effective-settings.xml effective-settings.xml
RUN \
  cat effective-settings.xml && \
  pwd &&\
  ls -al
EXPOSE 8889


