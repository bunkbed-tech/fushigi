# ---
# Layer 1: Build database as binary with migrations/data baked in
FROM golang:1.24.5-alpine AS builder

WORKDIR /app

# Download dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the source and build
COPY . .
RUN go build -o pocketbase main.go

# ---
# Layer 2: Serve build binary as backend-as-a-service
FROM alpine:3.20

WORKDIR /app

# Copy the built binary
COPY --from=builder /app/pocketbase /app/pocketbase

# Default command: run pocketbase in serve mode
CMD ["/app/pocketbase", "serve", "--http=0.0.0.0:8090"]
