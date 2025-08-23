
import 'package:flutter/material.dart';


class UiHelper{
  static CustomTextField(TextEditingController controller ,String text, IconData iconData,bool toHide){
    return TextFormField(
      controller: controller,
      obscureText: toHide,
      decoration: InputDecoration(
          prefixIcon: Icon(iconData),
          hintText: text,
          fillColor: Colors.grey[500],
          // filled: true,
          // border: OutlineInputBorder(
          //   borderRadius: BorderRadius.circular(40),
          // )
           ),
    );

  }

  // static CustomButton(BuildContext context,VoidCallback voidCallback,String title ){
  //   return Padding(
  //     padding: const EdgeInsets.all(10.0),
  //     child: GestureDetector(
  //       onTap: voidCallback,
  //       child: Container(
  //         height: height *0.07,
  //         width: width *.87,
  //         child: Center(child: Text(title,style: btnStyle,)),
  //         decoration: BoxDecoration(
  //             color: Colors.grey[500],
  //             borderRadius: BorderRadius.circular(20)),
  //       ),
  //     ),
  //   );
  // }

  static CustomListTile(VoidCallback voidCallback,String title,IconData iconData,Color color){
    return ListTile(
      title:  Text(title,style: TextStyle(color: color),),
      leading:  Icon(iconData,color: color,),
      onTap: voidCallback,

    );
  }

}