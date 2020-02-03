import hydra
import unittest


suite "Frame Header":

    test "Read":
        var stream = newStringStream("\x03\x00\x00\x06\x01\x2a\x00\x00\x00\x01\x01\x01")
        var header = Header.read(stream).unwrap()
        check(header.length == 3)
        check(header.frame_type == FrameType.Ping)
        check(header.flags == 1)
        check(header.stream_id == 42)

    test "Frame size error when the header does not have 9 bytes":
        var stream = newStringStream("\x00")
        var header = Header.read(stream)
        check(header.unwrap_error() == ErrorCode.FrameSize)

    test "Frame size error when frame payload has not enought bytes":
        var stream = newStringStream("\x03\x00\x00\x00\x01\x2a\x00\x00\x00\x01")
        var header = Header.read(stream)
        check(header.unwrap_error() == ErrorCode.FrameSize)

    test "Protocol error when frame payload has not enought bytes and targets the connection control stream":
        var stream = newStringStream("\x03\x00\x00\x00\x01\x00\x00\x00\x00\x00")
        var header = Header.read(stream)
        check(header.unwrap_error() == ErrorCode.Protocol)

    test "Protocol error when headers frame payload has not enought bytes":
        var stream = newStringStream("\x03\x00\x00\x01\x01\x2a\x00\x00\x00\x01")
        var header = Header.read(stream)
        check(header.unwrap_error() == ErrorCode.Protocol)

    test "Protocol error when settings frame payload has not enought bytes":
        var stream = newStringStream("\x03\x00\x00\x04\x01\x2a\x00\x00\x00\x01")
        var header = Header.read(stream)
        check(header.unwrap_error() == ErrorCode.Protocol)

    test "Protocol error when push promise frame payload has not enought bytes":
        var stream = newStringStream("\x03\x00\x00\x05\x01\x2a\x00\x00\x00\x01")
        var header = Header.read(stream)
        check(header.unwrap_error() == ErrorCode.Protocol)

    test "Protocol error when continuation frame payload has not enought bytes":
        var stream = newStringStream("\x03\x00\x00\x09\x01\x2a\x00\x00\x00\x01")
        var header = Header.read(stream)
        check(header.unwrap_error() == ErrorCode.Protocol)
