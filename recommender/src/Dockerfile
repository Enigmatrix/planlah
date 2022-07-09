FROM python:3.9.1
ADD . /recommender
WORKDIR /recommender
RUN pip install -r requirements.txt
EXPOSE 5000
CMD python app.py