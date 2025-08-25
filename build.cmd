set GOOS=linux
set GOARCH=amd64

cd webserver && pnpm install && pnpm build && cd .. && go build

docker build -t ghcr.io/jefflill/checkrr:latest .
docker push ghcr.io/jefflill/checkrr:latest
