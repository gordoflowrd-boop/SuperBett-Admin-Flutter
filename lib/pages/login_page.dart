import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  String mensaje = "";
  bool loading = false;

  static const String apiUrl =
      "https://superbett-api-production.up.railway.app/api";

  Future<void> login() async {
    final username = _userCtrl.text.trim();
    final password = _passCtrl.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => mensaje = "Ingresa usuario y contraseña");
      return;
    }

    setState(() {
      loading = true;
      mensaje = "Iniciando sesión...";
    });

    try {
      final res = await http.post(
        Uri.parse("$apiUrl/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode != 200) {
        setState(() => mensaje = data["error"] ?? "Credenciales inválidas");
        return;
      }

      if (!["admin", "central"].contains(data["usuario"]?["rol"])) {
        setState(() => mensaje = "Sin acceso al panel admin");
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", data["token"]);
      await prefs.setString("usuario", jsonEncode(data["usuario"]));

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, "/menu");
    } catch (e) {
      setState(() => mensaje = "Error de conexión");
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "SuperBett Admin",
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _userCtrl,
                decoration: const InputDecoration(labelText: "Usuario"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                onSubmitted: (_) => login(),
                decoration: const InputDecoration(labelText: "Contraseña"),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: loading ? null : login,
                child: Text(loading ? "Cargando..." : "Iniciar sesión"),
              ),
              const SizedBox(height: 10),
              Text(
                mensaje,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}