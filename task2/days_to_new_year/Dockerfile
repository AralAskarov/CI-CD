FROM python:3.10-slim

WORKDIR /app

COPY task2/days_to_new_year/requirements.txt /app/

RUN pip install --no-cache-dir -r requirements.txt

COPY . /app/

EXPOSE 8000

CMD ["python", "task2/days_to_new_year/manage.py", "runserver", "0.0.0.0:8000"]


