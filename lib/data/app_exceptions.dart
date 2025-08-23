

class AppExceptions implements Exception{
  final _message;
  final _prefix;
  AppExceptions([this._message, this._prefix]);

  String toString(){
    return "$_prefix $_message";
  }
}

class InternetException extends AppExceptions{
  InternetException([String? _message]) :super(_message, "No Internet");
}

class RequestTimeout extends AppExceptions{
  RequestTimeout([String? _message]) :super(_message, "Request Timeout");
}

class ServerException extends AppExceptions{
  ServerException([String? _message]) :super(_message, "Internal Server Exception");
}

class InvalidUrlException extends AppExceptions{
  InvalidUrlException([String? _message]) :super(_message, "Invalid Url provided");
}

class FetchDataException extends AppExceptions{
  FetchDataException([String? _message]) :super(_message, "Error while communication");
}

