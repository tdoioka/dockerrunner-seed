ARG BASE_IMAGE=ubuntu:18.04
FROM $BASE_IMAGE

RUN apt update && apt install -y --no-install-recommends \
	gosu \
	sudo \
 && apt -y clean

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN useradd -U -m user -s /bin/bash \
 && gpasswd -a user sudo \
 && echo "user:user" | chpasswd \
 && chmod a+x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD /bin/bash
