FROM nvcr.io/nvidia/pytorch:24.05-py3

WORKDIR /

RUN git clone https://github.com/hosseinsarshar/ml-engineering.git

ENV PYTHONPATH ./

COPY main.sh /

# Set permissions to make the script executable 
RUN chmod +x /main.sh
