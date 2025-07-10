import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'login_controller.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final LoginController controller = Get.put(LoginController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Obx(
              () => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Image.asset(
                    'assets/images/logo.png',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Iniciar Sesión',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: controller.emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.email),
                      errorText:
                          controller.errorMessage.value.contains('Correo')
                              ? controller.errorMessage.value
                              : null,
                    ),
                    onChanged: (_) {
                      if (controller.errorMessage.value.isNotEmpty)
                        controller.errorMessage.value = '';
                    },
                  ),
                  const SizedBox(height: 20),
                  RawKeyboardListener(
                    focusNode: FocusNode(),
                    onKey: (event) {
                      if (event.isKeyPressed(LogicalKeyboardKey.enter) ||
                          event.isKeyPressed(LogicalKeyboardKey.numpadEnter)) {
                        if (controller.emailController.text.isNotEmpty &&
                            controller.pinController.text.length == 6) {
                          controller.login();
                        }
                      }
                    },
                    child: Pinput(
                      controller: controller.pinController,
                      length: 6,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      defaultPinTheme: PinTheme(
                        width: 48,
                        height: 56,
                        textStyle: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                      ),
                      onChanged: (_) {
                        if (controller.errorMessage.value.isNotEmpty)
                          controller.errorMessage.value = '';
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (controller.errorMessage.value.isNotEmpty &&
                      !controller.errorMessage.value.contains('Correo'))
                    Text(
                      controller.errorMessage.value,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 12),
                  controller.isLoading.value
                      ? const CircularProgressIndicator()
                      : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: controller.login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Ingresar',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () async {
                      final user = await controller.autorizarParaRegistro();
                      if (user != null) {
                        Get.toNamed('/register', arguments: user);
                      }
                    },
                    child: const Text('¿No tienes cuenta? Registrate'),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
