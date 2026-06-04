FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html
COPY cases.html /usr/share/nginx/html/cases.html
COPY policy.html /usr/share/nginx/html/policy.html
COPY background.jpg /usr/share/nginx/html/background.jpg
COPY assets/ /usr/share/nginx/html/assets/

EXPOSE 80
