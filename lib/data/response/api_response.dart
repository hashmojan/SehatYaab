

import 'package:sehatyab/data/response/status.dart';

class ApiResponse{
  String? message;
  Status? status;
  String? data;

  ApiResponse.completed():status= Status.COMPLETED;
  ApiResponse.loading(): status= Status.LOADING;
  ApiResponse.error(): status=Status.ERROR;

  @override
  String toString(){
    return "Status :$status \nMessage :$message \nData :$data";
  }

}