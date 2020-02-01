# Hydra 🐉

HTTP/2 frames for Nim inspired by [Hyperframe](https://github.com/python-hyper/hyperframe)

[![Build Status](https://api.travis-ci.org/ducdetronquito/hydra.svg?branch=master)](https://travis-ci.org/ducdetronquito/hydra) [![License](https://img.shields.io/badge/license-public%20domain-ff69b4.svg)](https://github.com/ducdetronquito/hydra#license)

## Usage

Nota Bene: *Hydra is in its early stage, so every of its aspects is subject to changes* 🌪️

```nim
    import hydra
    import streams

    var stream = newStringStream("......")

    while not stream.atEnd():
        let header = Header.read(stream)

        # Eventually do something with the frame header...

        case header.frame_type:
        of FrameType.Ping:
            let frame = PingFrame.read(header, stream).unwrap()
        of FrameType.Data:
            let frame = DataFrame.read(header, stream).unwrap()
        of FrameType.RstStream:
            let frame = RstStream.read(header, stream).unwrap()
        else:
            discard
```

## License

**Hydra** is released into the **Public Domain**. 🎉🍻
