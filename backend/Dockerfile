# syntax=docker/dockerfile:1

FROM golang:1.18.2

WORKDIR /app

COPY backend/go.mod ./
COPY backend/go.sum ./
RUN go mod download

COPY backend .
RUN go install github.com/swaggo/swag/cmd/swag@latest && swag init
RUN go install github.com/google/wire/cmd/wire@latest && wire


RUN go build -o ./planlah
COPY .env ../.env

EXPOSE 8080

CMD [ "./planlah" ]