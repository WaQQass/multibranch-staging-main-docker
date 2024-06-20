FROM python:3.9-slim

# Install MySQL client
RUN apt-get update && apt-get install -y default-mysql-client

WORKDIR /app

COPY app.py .
COPY nginx_html/index.html .
COPY requirements.txt .

RUN pip install -r requirements.txt

# Expose port for Flask app
EXPOSE 5000

CMD ["python", "app.py"]
