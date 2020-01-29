import hydra
import streams
import unittest


suite "Frame Header":

    test "Read":
        var stream = newStringStream("\x00\x07\x4f\x06\x01\x2a\x00\x00\x00")
        var header = Header.read(stream)
        check(header.length == 1871)
        check(header.frame_type == FrameType.Ping)
        check(header.flags == 1)
        check(header.stream_id == 42)
