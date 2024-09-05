FROM nginx

COPY nginx.conf /etc/nginx/conf.d/default.conf

COPY static/ /usr/share/nginx/html/

LABEL maintainer="Cherepanov Vladislav"

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
