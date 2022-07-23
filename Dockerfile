FROM python:3.9

RUN groupadd -r uwsgi_group && useradd -r -g uwsgi_group uwsgi_user
RUN pip install Flask==2.1.3 uWSGI==2.0.20 requests redis
WORKDIR /app
COPY app /app
COPY cmd.sh /

EXPOSE 9090 9191
USER uwsgi_user

CMD ["/cmd.sh"]