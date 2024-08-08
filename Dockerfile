FROM nginx

COPY static /usr/share/nginx/html
COPY nginx.conf /etc/nginx/

EXPOSE 80