# buildkit-cicd-cached

## Solution pushing image (no --from-cache)

Exclude of .git is commented to allow mvn to execute. But normally .git copy should execute later to allow for caching (git is always changed)

```shell
printf '<project><modelVersion>4.0.0</modelVersion><groupId>org.raisercostin</groupId><artifactId>myapp</artifactId><version>0.1</version><packaging>jar</packaging></project>' > pom.xml

printf '#syntax=docker/dockerfile:1.7-labs\nFROM myapp:latest \nCOPY --exclude=.git-commentedout/ --exclude=dump/ . /\nRUN ls -al&& ls -al /root/.m2||echo hm && mvn pl.project13.maven:git-commit-id-plugin:revision|| echo error ignored to allow cache && echo change to invalidate cache v5' | docker buildx build -f- . --output=type=image,name=myapp --tag=myapp:latest --progress=plain --cache-from=myapp:latest --output=type=local,dest=dump
```

## Solution pushing build stage - best

1. Create and push build-image: contains all intermediate .m2 files in image and use previous such build-image
2. Create and push runtime-image: using the previous build-image

```shell
echo build and keep cache - https://docs.docker.com/build/exporters/
docker buildx build --target myapp-build --output=type=image,name=myapp/myapp-build-cache:latest,push=true .  --cache-from=myapp/myapp-build-cache:latest
#docker buildx build --target myapp-build --output=type=registry,name=myapp/myapp-build-cache:latest .  --cache-from=myapp/myapp-build-cache:latest
docker buildx build --target myapp-runtime --output=type=image,name=myapp/myapp:latest .

echo inspect content of images if needed
printf 'FROM myapp-build/build-cache \nCOPY . /' | docker buildx build -f- --output context-build-cache .
printf 'FROM myapp-build/myapp \nCOPY . /' | docker buildx build -f- -o context-myapp .
docker images |grep myapp
```

## Solution exporting intermediate stage

A template on how a cached CICD multistage buildkit docker project can be done.

See `Dockerfile` for the 3 stages:

- myapp-build - the building part
- myapp-cache - exists solely for the export --output and triggered via --target. But also helps a second run of build since will create a local cache.
- myapp-runtime - to create the final runtime image

```shell
echo Create cache image and export cache
docker buildx build --cache-from "mytest:latest" -t mytest:latest -f Dockerfile . --output . --target=myapp-cache
# $(docker image inspect mytest:latest > /dev/null 2>&1 && echo "--cache-from mytest:latest")
echo Create runtime image (that will leverage local docker cache) but also exported .m2-cached
docker buildx build --cache-from "mytest:latest" -t mytest:latest -f Dockerfile . --target=myapp-runtime
```

Solution keywords: docker, gitlab/github, buildx, buildkit, stage, exporter, .m2, cache, cicd

## References

- <https://aymdev.io/en/blog/post/using-cache-in-gitlab-ci-with-docker-in-docker> - clarifies the multiple types of "caching"
- <https://stackoverflow.com/questions/63891067/is-there-a-way-to-export-files-during-a-docker-build>
- <https://docs.docker.com/reference/cli/docker/buildx/build/#target>
- <https://docs.docker.com/reference/cli/docker/buildx/build/#output>
- <https://www.reddit.com/r/gitlab/comments/plk3js/cache_m2_gitlab_runner/>
- <https://github.com/moby/buildkit#export-cache> --cache-from --cache-to
- <https://www.augmentedmind.de/2022/06/12/gitlab-vs-docker-caching-pipelines/>
- <https://www.augmentedmind.de/2022/06/12/gitlab-vs-docker-caching-pipelines/>
- <https://reece.tech/posts/extracting-files-multi-stage-docker/>
