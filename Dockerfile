# Use the official slim Python image from the Docker Hub
FROM python:3.8-slim-bullseye

# Set environment variables to prevent Python from writing pyc files to disk
# and to ensure stdout and stderr are unbuffered
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Create a directory for the app
RUN mkdir /app
WORKDIR /app

# Install Nginx
RUN apt-get update && apt-get install -y nginx

# Install dependencies
COPY requirements.txt /app/
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

# Copy the Django project files
COPY . /app/
WORKDIR /app/RootToRoot

# Run migrations and collect static files
RUN python manage.py makemigrations
RUN python manage.py migrate --no-input
RUN python manage.py collectstatic --no-input

# Expose the port that the app will run on
EXPOSE 8000

# Run the Gunicorn server
CMD ["gunicorn", "RootToRoot.wsgi:application", "--bind", "0.0.0.0:8000"]