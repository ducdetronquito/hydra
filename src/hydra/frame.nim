import streams
import header

type
    Frame* = object


proc read_header*(cls: type[Frame], stream: StringStream): Header =
    return Header.read(stream)
