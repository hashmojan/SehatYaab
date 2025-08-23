import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sehatyab/res/components/round_button.dart';

import '../colors/app_colors.dart';

class GeneralExceptionWidget extends StatefulWidget {
  final VoidCallback onPress;
  const GeneralExceptionWidget({super.key,required this.onPress});

  @override
  State<GeneralExceptionWidget> createState() => _GeneralExceptionWidgetState();
}

class _GeneralExceptionWidgetState extends State<GeneralExceptionWidget> {

  @override
  Widget build(BuildContext context) {
    double height=MediaQuery.of(context).size.height;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          SizedBox(height: height* .15,),
          Icon(Icons.cloud_off,size: 50,color: AppColors.redColor,),
          const Padding(
            padding: EdgeInsets.only(top:30),
            child: Center(child:
            Text("We're unable to to process your request \n please try again",
              textAlign: TextAlign.center,)),
          ),
          SizedBox(height: height* .15,),
          RoundButton(onPress: (){}, title: "Retry",),
        ],
      ),
    );
  }
}
