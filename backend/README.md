## Notes
- First build will fail, need to run `swag init` atleast once (refer below)

## Firebase
- Paste `planlah..adminsdk...json` into `/backend`.
- Need to set `GOOGLE_APPLICATION_CREDENTIALS` environment variable to the path of the above file.

## Swagger
- Run `swag init` to regen docs then visit [Swagger Docs](http://localhost:8080/swagger/index.html)
  - if you don't have swag, run `go install github.com/swaggo/swag/cmd/swag`
- Use descriptive [Swagger commenting format](https://github.com/swaggo/swag#declarative-comments-format)