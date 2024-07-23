# buildkit-cicd-cached

A template on how a cached CICD multistage buildkit docker project can be done.

See `Dockerfile` for the 3 stages:

- myapp-build - the building part
- myapp-cache - exists solely for the export --output and triggered via --target. But also helps a second run of build since will create a local cache.
- myapp-runtime - to create the final runtime image

```shell
echo Create cache image and export cache
docker buildx build --cache-from "mytest:latest" -t mytest:latest -f Dockerfile . --output . --target=myapp-cache
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
