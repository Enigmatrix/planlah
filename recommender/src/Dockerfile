FROM python:3.9.1
WORKDIR /recommender/src
ADD recommender/src .
ADD .env ../../.env
RUN pip install -r requirements.txt
EXPOSE 5000
CMD python app.py