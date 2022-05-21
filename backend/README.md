## Notes
- First build will fail:
  - need to run `swag init` atleast once (refer below)
  - need to run `wire` atleast once (refer below)

### Firebase
- Paste `planlah..adminsdk...json` into `/backend`.
- Need to set `GOOGLE_APPLICATION_CREDENTIALS` environment variable to the path of the above file.

### Wire (Dependency Injection)
- Run `wire` to turn compile `deps.go` and inject dependencies
  - install `wire` using `go install github.com/google/wire/cmd/wire@latest`
- If you want to change `deps.go`, remove the `+build wireinject` at the top then make the changes.
  Remember to add it back after the changes are done.

### Swagger
- Run `swag init` to regen docs then visit [Swagger Docs](http://localhost:8080/swagger/index.html)
  - install `swag` using `go install github.com/swaggo/swag/cmd/swag`
- Use descriptive [Swagger commenting format](https://github.com/swaggo/swag#declarative-comments-format)