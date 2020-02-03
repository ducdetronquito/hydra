# Hydra 🐉

HTTP/2 frames for Nim inspired by [Hyperframe](https://github.com/python-hyper/hyperframe)

[![Build Status](https://api.travis-ci.org/ducdetronquito/hydra.svg?branch=master)](https://travis-ci.org/ducdetronquito/hydra) [![License](https://img.shields.io/badge/license-public%20domain-ff69b4.svg)](https://github.com/ducdetronquito/hydra#license)

## Usage

Nota Bene: *Hydra is in its early stage, so every of its aspects is subject to changes* 🌪️

```nim
    import hydra

    var stream = newStringStream("......")

    let header = Header.read(stream).unwrap()

    # Eventually do something with the frame header...

    case header.frame_type:
    of FrameType.Data:
        let frame = DataFrame.read(header, stream).unwrap()
    of FrameType.Headers:
        let frame = HeadersFrame.read(header, stream).unwrap()
    of FrameType.Priority:
        let frame = PriorityFrame.read(header, stream).unwrap()
    of FrameType.RstStream:
        let frame = RstStreamFrame.read(header, stream).unwrap()
    of FrameType.Settings:
        let frame = SettingsFrame.read(header, stream).unwrap()
    of FrameType.PushPromise:
        let frame = PushPromise.read(header, stream).unwrap()
    of FrameType.Ping:
        let frame = PingFrame.read(header, stream).unwrap()
    of FrameType.GoAway:
        let frame = GoAwayFrame.read(header, stream).unwrap()
    else:
        discard
```

## License

**Hydra** is released into the **Public Domain**. 🎉🍻
