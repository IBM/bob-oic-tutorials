FROM docker.io/python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

COPY load_generator.py .

RUN useradd -m -u 1001 appuser && \
    chown -R appuser:appuser /app

USER appuser

CMD ["python", "load_generator.py"]