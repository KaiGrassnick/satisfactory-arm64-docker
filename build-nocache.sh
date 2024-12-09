docker build --no-cache --build-arg DOCKER_USER=$(grep DOCKER_USER .env | cut -d '=' -f2) --build-arg DOCKER_GROUP=$(grep DOCKER_GROUP .env | cut -d '=' -f2) -t satisfactory-arm64 .
