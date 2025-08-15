FROM python:3.13-alpine

WORKDIR /app

COPY django-crm/requirements.txt .

# Runtime deps first (kept): provides libmariadb.so.3 for mysqlclient at runtime
RUN apk add --no-cache mariadb-connector-c \
     && apk add --no-cache --virtual .build-deps \
         gcc musl-dev mariadb-connector-c-dev pkgconf \
     && pip install --no-cache-dir -r requirements.txt \
     && apk del .build-deps

COPY django-crm .
COPY settings.py /app/webcrm/settings.py

# Start app
CMD ["sh", "-c", "python manage.py migrate && python manage.py runserver 0.0.0.0:8080"]
#CMD ["tail", "-f", "/dev/null"]