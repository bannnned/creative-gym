FROM golang:1.24.1-alpine AS build

WORKDIR /src

RUN apk add --no-cache ca-certificates

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /out/api ./cmd/api
RUN CGO_ENABLED=0 GOOS=linux go build -o /out/db ./cmd/db

FROM alpine:3.22

WORKDIR /app

RUN apk add --no-cache ca-certificates && adduser -D -H -u 10001 appuser

COPY --from=build /out/api /app/api
COPY --from=build /out/db /app/db
COPY migrations /app/migrations
COPY seeds /app/seeds

USER appuser

EXPOSE 8080

CMD ["/app/api"]
