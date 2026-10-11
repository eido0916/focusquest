FROM dart:stable AS build
WORKDIR /app
COPY party_server.dart .
RUN dart compile exe party_server.dart -o /app/party-server

FROM scratch
WORKDIR /app
COPY --from=build /runtime/ /
COPY --from=build /app/party-server /app/party-server
ENV PORT=8080
EXPOSE 8080
CMD ["/app/party-server"]
