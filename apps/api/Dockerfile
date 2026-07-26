FROM golang:1.24.1-alpine AS build

WORKDIR /src

RUN apk add --no-cache ca-certificates

COPY go.mod go.sum ./
RUN go mod download

COPY . .
ARG BUILD_SHA=dev
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags "-X main.buildCommit=${BUILD_SHA}" \
    -o /out/api ./cmd/api
RUN CGO_ENABLED=0 GOOS=linux go build -o /out/db ./cmd/db
RUN CGO_ENABLED=0 GOOS=linux go build -o /out/backup ./cmd/backup

FROM alpine:3.22

WORKDIR /app

RUN apk add --no-cache ca-certificates && adduser -D -H -u 10001 appuser

COPY --from=build /out/api /app/api
COPY --from=build /out/db /app/db
COPY --from=build /out/backup /app/backup
COPY migrations /app/migrations
COPY seeds /app/seeds

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=6 \
  CMD wget -qO- http://127.0.0.1:8080/readyz >/dev/null || exit 1

CMD ["/app/api"]
