
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import "package:http/http.dart" as http;

import '../app_exceptions.dart';
import 'base_api_services.dart';


class NetworkApiServices extends BaseApiServices{

  Future<dynamic> getApi(String url)async{

    log(url as num);
    dynamic responseJson;
    try{
      final response=await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      responseJson=returnResponse(response);
    }on SocketException{
      throw InternetException('');
    }on TimeoutException{
      throw TimeoutException('');
    }
    return responseJson;

  }

  Future<dynamic> postApi(var data,String url)async{

    log(url as num);
    log(data);
    dynamic responseJson;
    try{
      final response=await http.post(Uri.parse(url),
        body: data
      ).timeout(const Duration(seconds: 10));
      responseJson=returnResponse(response);
    }on SocketException{
      throw InternetException('');
    }on TimeoutException{
      throw TimeoutException('');
    }
    return responseJson;

  }

  returnResponse(http.Response response) {
    switch(response.statusCode){
      case 200:
        dynamic responseJson=jsonDecode(response.body);
        return responseJson;
      case 400:
        dynamic responseJson=jsonDecode(response.body);
        return responseJson;
      default:
        throw FetchDataException('');
    }
  }
}