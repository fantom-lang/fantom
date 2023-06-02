# Fantom Programming Language

Fantom is a portable language that runs on the JVM and modern web browsers. It
features a familiar Java-like syntax, static (and dynamic) typing, elegant
system library, closures, immutability, actor concurrency, and much more.

```fantom
// Hello from Fantom!
class HelloWorld
{
  static Void main()
  {
    echo("Hello, World!")
  }
}
```

## Fantom Website

[https://fantom.org](http://fantom.org)

## Installing

Download the latest official release from [fantom.org](http://fantom.org).
See [Setup](https://fantom.org/doc/docTools/Setup) for installation details.

Installers are also available for macOS and Windows:

  * macOS: `brew install fantom`
  * Windows: [installer](https://github.com/Fantom-Factory/fantomWindowsInstaller/releases)

### Docker

This repo vends a docker image that can be downloaded and run locally using:
```bash
docker run -it ghcr.io/fantom-lang/fantom:latest bash
```

It can be used in other dockerfiles using the `FROM` command:
```dockerfile
FROM ghcr.io/fantom-lang/fantom:latest AS build
```

## Community

We are most active on the [Forum](http://fantom.org/forum/topic), but also hang out on [Slack](https://join.slack.com/t/fantom-lang/shared_invite/zt-3se21er9-Tm~L2lpYel6jcqYKPcdkBg). 

Bugs and feature requests should be reported on the Forum.

## Contributing

See [contrib.md](https://github.com/fantom-lang/fantom/blob/master/contrib.md)
for how to contribute to Fantom.
