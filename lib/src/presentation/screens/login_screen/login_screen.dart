import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Card(
        elevation: 5.0,
        child: SizedBox(
          height: 400,
          width: 400,
          child: FormField(
            builder:(field) {
              return Column(
                children: [
                  CircleAvatar(),
                  Container(height: 100),
                  TextField(),
                  TextField(),
                  SizedBox(height: 25.0,)
                ],
              );
            },),
        ),
      ),
    );
  }
}