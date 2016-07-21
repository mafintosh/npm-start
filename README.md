# npm-start-container

[npm start](https://www.npmjs.org/doc/cli/npm-start-container.html) written in bash that propagates kill to subprocesses

```
npm install npm-start-container -g
```

## Usage

Usage is exactly the same as [npm start](https://www.npmjs.org/doc/cli/npm-start-container.html)

```
$ cd some-folder-with-a-package-json
$ npm-start-container
```

The difference is that when it receives `SIGTERM` it will kill all subprocesses as well (which [npm start](https://www.npmjs.org/doc/cli/npm-start-container.html) doesn't do)
and wait for them to exit

```
$ kill pid-of-npm-start-container # this will actually kill the node process
```

Also memory usage for long running processes might be a bit lower since you do not need to spawn an additional node process to start npm

## License

MIT