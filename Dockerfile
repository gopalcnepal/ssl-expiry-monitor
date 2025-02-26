# Using slim offcial image for smaller size
FROM python:3.12-slim

# Setting working directory
WORKDIR /app

# Copy the requirements file
COPY requirements.txt .

# Upgrade pip and Install dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy the application code
COPY app/ app/

# Expose the Flask port
EXPOSE 5000

# Run Gunicorn using the Flask app defined in `app/__init__.py`
CMD ["gunicorn", "-b", "0.0.0.0:5000", "app:app"]