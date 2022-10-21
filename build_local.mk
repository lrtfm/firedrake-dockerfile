#

docker container 内部用户和本地用户 id 不一致时, 共享的目录不能在 docker 内部更改, 若需可写, 可基于下载的镜像构建本地镜像. 

1. 下载 `firedrake` 镜像 

```bash
docker pull lrtfm/firedrake-real-int32
```


2. 下载构建本地镜像脚本, 并构建本地镜像

```bash
git clone https://github.com/lrtfm/firedrake-dockerfile.git
cd firedrake-dockerfile
chmod +x build.sh
./build.sh
```

3. 查看构建的镜像

输出应该有以用户名结果的一个镜像, 就是上一步构建的
```bash
docker image ls 
```

4. 启动一个 Container 

下面命令启动 一个名字为 firedrake-$USER 的 container

```
docker run -d -v $HOME:$HOME --name firedrake-$USER firedrake-real-int32-local-$USER
```

5. VS Code remote 连接服务器, 然后 attach 到创建的 contaier 即可

