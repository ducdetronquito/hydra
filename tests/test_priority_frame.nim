import hydra
import strutils
import unittest


suite "Priority Frame":

    test "Read":
        var stream = newStringStream("\x07\x00\x00\x80\x2a")
        let header = Header(frame_type: FrameType.Priority, length: 5'u32, stream_id: 1'u32)
        let frame = PriorityFrame.read(header, stream).unwrap()
        check(frame.priority.weight == 42'u8)
        check(frame.priority.exclusive == true)
        check(frame.priority.stream_dependency == 7'u32)

    test "Protocol error when targets the connection control stream":
        let header = Header(frame_type: FrameType.Priority, length: 4'u32, stream_id: 0'u8)
        var stream = newStringStream("")
        let result = PriorityFrame.read(header, stream)
        check(result.unwrap_error() == ErrorCode.Protocol)

    test "Frame size error when the header length is not 5":
        let header = Header(frame_type: FrameType.Priority, length: 8'u32, stream_id: 1'u8)
        var stream = newStringStream("")
        let result = PriorityFrame.read(header, stream)
        check(result.unwrap_error() == ErrorCode.FrameSize)

    test "Serialize":
        let header = Header(frame_type: FrameType.Priority, length: 5'u32, stream_id: 1'u32)
        let priority = Priority(weight: 42'u8, exclusive: true, stream_dependency: 7'u8)
        let frame = PriorityFrame(header: header, priority: priority)
        check(frame.serialize() == [
            0'u8, 0'u8, 5'u8, 2'u8, 0'u8, 0'u8, 0'u8, 0'u8, 1'u8,
            128'u8, 0'u8, 0'u8, 7'u8, 42'u8
        ])
