import hydra
import streams
import unittest


suite "Frame Header":

    test "Frame Header":
        var stream = newStringStream("\x00\x07\x4f\x0f\x14\xFF\xFF\xFF\xFF")
        var header = Frame.read_header(stream)
        check(header.length == 1871)
        check(header.frame_type == '\x0f')
        check(header.flags == '\x14')
        check(header.stream_id == 2147483647)
