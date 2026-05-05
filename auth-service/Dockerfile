FROM golang:1.21-alpine AS builder

WORKDIR /app

COPY . .
RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux go build -o auth-service .

FROM alpine:3.20

WORKDIR /app
RUN apk add --no-cache ca-certificates

COPY --from=builder /app/auth-service /app/auth-service

EXPOSE 8001

CMD ["/app/auth-service"]
