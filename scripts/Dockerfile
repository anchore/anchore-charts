FROM python:3

WORKDIR /app

COPY helpers.py /app/
COPY convert.py /app/
COPY mappings.py /app/

RUN pip install argparse pyyaml

ENTRYPOINT ["python3", "convert.py"]

CMD ["-e", "values.yaml"]