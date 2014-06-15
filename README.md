# npm-start

[npm start](https://www.npmjs.org/doc/cli/npm-start.html) that propagates kill to all subprocesses

```
npm install npm-start -g
```

## Usage

Usage is exactly the same as [npm start](https://www.npmjs.org/doc/cli/npm-start.html)

```
$ cd some-folder-with-a-package-json
$ npm-start
```

The difference is that when it receives `SIGTERM` it will kill all subprocesses as well (which [npm start](https://www.npmjs.org/doc/cli/npm-start.html) doesn't do)
and wait for them to exit

```
$ kill pid-of-npm-start # this will actually kill the node process
```

## License

MIT