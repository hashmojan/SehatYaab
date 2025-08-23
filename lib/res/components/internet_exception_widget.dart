

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class InterNetExceptionWidget extends StatefulWidget {
  final VoidCallback onPress;
  const InterNetExceptionWidget({super.key,required this.onPress});

  @override
  State<InterNetExceptionWidget> createState() => _InterNetExceptionWidgetState();
}

class _InterNetExceptionWidgetState extends State<InterNetExceptionWidget> {

  @override
  Widget build(BuildContext context) {
    double height=MediaQuery.of(context).size.height;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          SizedBox(height: height* .15,),
          Icon(Icons.cloud_off,size: 50,color: Colors.red,),
          const Padding(
            padding: EdgeInsets.only(top:30),
            child: Center(child:
            Text("We're unable to show you result please check your Internet connection and try again",
              textAlign: TextAlign.center,)),
          ),
          SizedBox(height: height* .15,),
          InkWell(
            onTap: widget.onPress,
            child: Container(
              height: 44,
              width: 160,
              child: Center(child: Text("Retry",
                style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.white))),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: Colors.green,
              ),
            ),
          )
        ],
      ),
    );
  }
}
