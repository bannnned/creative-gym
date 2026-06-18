FROM node:24-alpine AS web-build

WORKDIR /src/apps/web

COPY apps/web/package.json apps/web/package-lock.json ./
RUN npm ci

COPY apps/web ./
RUN npm run build

FROM golang:1.24.1-alpine AS api-build

WORKDIR /src/apps/api

RUN apk add --no-cache ca-certificates

COPY apps/api/go.mod apps/api/go.sum ./
RUN go mod download

COPY apps/api ./
RUN CGO_ENABLED=0 GOOS=linux go build -o /out/api ./cmd/api
RUN CGO_ENABLED=0 GOOS=linux go build -o /out/db ./cmd/db

FROM alpine:3.22

WORKDIR /app

RUN apk add --no-cache ca-certificates && adduser -D -H -u 10001 appuser

COPY --from=api-build /out/api /app/api
COPY --from=api-build /out/db /app/db
COPY --from=api-build /src/apps/api/migrations /app/migrations
COPY --from=api-build /src/apps/api/seeds /app/seeds
COPY --from=web-build /src/apps/web/dist /app/web

ENV HTTP_ADDR=:8080
ENV WEB_STATIC_DIR=/app/web

USER appuser

EXPOSE 8080

CMD ["/app/api"]
