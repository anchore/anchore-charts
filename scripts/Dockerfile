FROM python:3@sha256:cc7372fe4746ca323f18c6bd0d45dadf22d192756abc5f73e39f9c7f10cba5aa

WORKDIR /app

COPY helpers.py /app/
COPY convert.py /app/
COPY mappings.py /app/

RUN pip install argparse pyyaml

ENTRYPOINT ["python3", "convert.py"]

CMD ["-e", "values.yaml"]