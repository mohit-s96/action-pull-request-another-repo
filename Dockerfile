FROM alpine/git


RUN wget -q  https://api.github.com/repos/cli/cli/releases/latest \
    && wget -q $(cat latest | grep linux_amd64.tar.gz | grep browser_download_url | grep -v .asc | cut -d '"' -f 4) \
    && apk add bash \
    && tar -xvzf gh*.tar.gz \
    && mv gh*/bin/gh /usr/local/bin/ \
    && rm -fr *
SHELL ["/bin/bash", "-c"] 

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/bin/bash", "/entrypoint.sh" ]