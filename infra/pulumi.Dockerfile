FROM pulumi/pulumi

COPY requirements.txt /
RUN pip install -r /requirements.txt
