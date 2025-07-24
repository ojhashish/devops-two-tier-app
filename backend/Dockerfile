# backend/Dockerfile
# Stage 1: Build stage
FROM python:3.9-slim-buster as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Stage 2: Production stage
FROM python:3.9-slim-buster
WORKDIR /app
COPY --from=builder /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
COPY --from=builder /usr/local/bin/flask /usr/local/bin/flask
COPY app.py .
EXPOSE 5001
CMD ["python", "app.py"]

