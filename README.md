# Wolfree Dockerfile
There are many ways to host a Wolfree mirror site.
You can use Docker or take any other approach you prefer.

## How to use Docker
1.  Install Docker.
    https://www.docker.com/

2.  Run the following command.

    ```
    docker build --progress=plain --tag wolfree https://try.gitea.io/wolfree/wolfree-dockerfile.git
    ```

3.  Run the following command.

    ```
    docker run --interactive --tty --publish 80:80 wolfree
    ```

4.  Docker Engine will output two Web addresses. For example,

    ```
    ----------------------------------------------------------------------
    Install Firefox and try:
    http://127.0.0.1/
    Install Tor Browser and try:
    http://pz7cewj2umcccjvfcviofyjcqigzgjfk3j7forlrwczrfu5zoe57vtad.onion/
    ----------------------------------------------------------------------
    ```

5.  Open Firefox and Tor browser, enter the Web addresses, and try the Wolfree mirror sites.

## Repository Mirror
You can try other Gitea servers. For example,
```
docker build --progress=plain --tag wolfree https://try.gitea.io/wolfree/wolfree-dockerfile.git
docker build --progress=plain --tag wolfree https://git.disroot.org/wolfree/wolfree-dockerfile.git
docker build --progress=plain --tag wolfree https://git.kiwifarms.net/wolfree/wolfree-dockerfile.git
docker build --progress=plain --tag wolfree http://it7otdanqu7ktntxzm427cba6i53w6wlanlh23v5i3siqmos47pzhvyd.onion/wolfree/wolfree-dockerfile.git
```

## LibRedirect
You can modify some functions to create LibRedirect-friendly mirrors.
```
sed -i 's/\/\/ f8RCUrgvdPqq//' /usr/share/nginx/html/input/wolfree.js
mv /libredirect/index.html     /usr/share/nginx/html/
mv /libredirect/instances.json /usr/share/nginx/html/
rm /usr/share/nginx/html/mirror/index.html
rm /usr/share/nginx/html/dmca/index.html
rm /usr/share/nginx/html/acknowledgment/index.html
```
