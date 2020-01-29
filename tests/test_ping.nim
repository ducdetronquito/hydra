import hydra
import streams
import unittest


suite "Ping Frame":

    test "Read":
        let header = Header(length: 8, frame_type: FrameType.Ping, stream_id: 0)
        var stream = newStringStream("\x2a\x00\x00\x00\x00\x00\x00\x00")
        let frame = PingFrame.read(header, stream)

        check(frame.opaque_data == 42'u64)
