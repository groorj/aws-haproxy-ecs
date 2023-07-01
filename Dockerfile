FROM --platform=linux/X86_64 haproxy:lts-alpine3.18
EXPOSE 8080 8888
COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
COPY my_redirect_list.map /usr/local/etc/haproxy/my_redirect_list.map
