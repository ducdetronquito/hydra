import hydra
import streams
import unittest


suite "Ping Frame":

    test "Read":
        let header = Header(frame_type: FrameType.Ping)
        var stream = newStringStream("\x2a\x00\x00\x00\x00\x00\x00\x00")
        let frame = PingFrame.read(header, stream)

        check(frame.opaque_data == 42'u64)

    test "Has flag ACK":
        let header = Header(frame_type: FrameType.Ping, flags: 1'u8)
        let frame = PingFrame(header: header)
        check(frame.is_ack())

    test "Does not have ACK flag":
        let header = Header(frame_type: FrameType.Ping, flags: 254'u8)
        let frame = PingFrame(header: header)
        check(frame.is_ack() == false)
