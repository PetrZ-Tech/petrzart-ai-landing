FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html
COPY policy.html /usr/share/nginx/html/policy.html
COPY background.jpg /usr/share/nginx/html/background.jpg

EXPOSE 80
