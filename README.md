
Create build nodes

```bash
docker buildx create --name mixed --node macos \
    --driver-opt network=host --buildkitd-flags '--allow-insecure-entitlement network.host' \
    --platform linux/arm64,linux/riscv64,linux/ppc64le,linux/s390x,linux/mips64le,linux/mips64,linux/arm/v7,linux/arm/v6

docker buildx create --name mixed --append --node ubuntu \
    --driver-opt network=host --buildkitd-flags '--allow-insecure-entitlement network.host' \
    --platform linux/amd64,linux/amd64/v2,linux/386 ssh://ama-ra18

docker buildx use mixed
```
