FROM python:3.9.1
WORKDIR /recommender/src
ADD recommender/src/requirements.txt .
RUN pip install -r requirements.txt
ADD recommender/src .
ADD .env ../../.env
EXPOSE 5000
CMD python app.py