import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'register_controller.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final RegisterController controller = Get.put(RegisterController());
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Usuario')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Obx(() {
              if (!controller.puedeRegistrar) {
                return const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 40),
                    Icon(Icons.lock_outline, size: 80, color: Colors.red),
                    SizedBox(height: 24),
                    Text(
                      'No tienes permisos para registrar nuevos usuarios.',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              }
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Icon(
                    Icons.person_add,
                    size: 80,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Registrar Usuario',
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
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller.userNameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre de usuario',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Pinput(
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
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value:
                        controller.perfilController.value.isEmpty
                            ? null
                            : controller.perfilController.value,
                    items:
                        controller.perfiles
                            .map(
                              (perfil) => DropdownMenuItem(
                                value: perfil,
                                child: Text(perfil),
                              ),
                            )
                            .toList(),
                    onChanged:
                        (val) => controller.perfilController.value = val ?? '',
                    decoration: InputDecoration(
                      labelText: 'Perfil de usuario',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.security),
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (controller.errorMessage.value.isNotEmpty)
                    Text(
                      controller.errorMessage.value,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (controller.successMessage.value.isNotEmpty)
                    Text(
                      controller.successMessage.value,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 12),
                  controller.isLoading.value
                      ? const CircularProgressIndicator()
                      : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: controller.registrar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Registrar',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                  const SizedBox(height: 40),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
