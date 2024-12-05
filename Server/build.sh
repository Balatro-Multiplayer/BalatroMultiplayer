docker build -f Dockerfile.build -t server-builder .

mkdir -p releases

docker create --name temp server-builder
docker cp temp:/app/dist/server-win.exe ./releases/
docker cp temp:/app/dist/server-linux ./releases/
docker cp temp:/app/dist/server-macos ./releases/
docker rm temp