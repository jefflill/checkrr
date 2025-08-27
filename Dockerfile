FROM alpine:latest
LABEL maintainer="jeff@lill.io"
COPY checkrr /checkrr
RUN apk update
RUN apk add ffmpeg
RUN apk add libmfx
RUN apk add libva-utils
RUN apk add mesa
RUN apk add intel-media-driver
RUN apk add tzdata
WORKDIR "/"
ENTRYPOINT [ "/checkrr" ]