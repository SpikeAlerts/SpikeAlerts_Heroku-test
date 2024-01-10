FROM python:latest

COPY . ./

RUN pip install -r requirements.txt

ENV PYTHONPATH "${PYTHONPATH}:/usr/app/"

CMD ["python", "App/aq_spikealerts.py"]