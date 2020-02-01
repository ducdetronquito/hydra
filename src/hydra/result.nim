type
    ResultError* = object of Exception

    Result*[T, E] = object
        case ok: bool
        of false:
            error: E
        of true:
            value: T


template Err*(R: type Result, x: auto): auto =
    R(ok: false, error: x)


template Err*(x: auto): auto =
    typeof(result).Err(x)


template Ok*(R: type Result, x: auto): auto =
    R(ok: true, value: x)


template Ok*(x: auto): auto =
    typeof(result).Ok(x)


template is_err*[T, E](self: Result[T, E]): bool =
    not self.ok


template is_ok*[T, E](self: Result[T, E]): bool =
    self.ok


template unwrap*[T, E](self: Result[T, E]): auto =
    if self.is_err():
        raise newException(ResultError, "Trying to access a value but the result is an error: " & $self.error)
    self.value


template unwrap_error*[T, E](self: Result[T, E]): auto =
    if self.is_ok():
        raise newException(ResultError, "Trying to access an error but the result is a value: " & $self.value)
    self.error
