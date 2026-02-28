import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _userFocus = FocusNode();
  final _passFocus = FocusNode();

  String  _msg       = "";
  bool    _loading   = false;
  bool    _showPass  = false;
  bool    _hasError  = false;

  late AnimationController _shakeCtrl;
  late Animation<double>   _shakeAnim;

  static const String _api = "https://superbett-api-production.up.railway.app/api";

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -8.0),  weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0),   weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0),    weight: 1),
    ]).animate(_shakeCtrl);
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _userFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final user = _userCtrl.text.trim();
    final pass = _passCtrl.text;

    if (user.isEmpty || pass.isEmpty) {
      _setError("Ingresa usuario y contraseña");
      return;
    }

    setState(() { _loading = true; _msg = ""; _hasError = false; });

    try {
      final res = await http.post(
        Uri.parse("$_api/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": user, "password": pass}),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode != 200) {
        _setError(data["error"] ?? "Credenciales inválidas");
        return;
      }

      if (!["admin", "central"].contains(data["usuario"]?["rol"])) {
        _setError("Sin acceso al panel admin");
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token",   data["token"]);
      await prefs.setString("usuario", jsonEncode(data["usuario"]));

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, "/menu");

    } catch (_) {
      _setError("Error de conexión");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setError(String msg) {
    setState(() { _msg = msg; _hasError = true; });
    _shakeCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: Column(children: [
          // ── Franja superior con logo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(0, 40, 0, 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              boxShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 4))],
            ),
            child: Column(children: [
              // Ícono
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Color(0x331A237E), blurRadius: 20, offset: Offset(0, 8))],
                ),
                child: const Center(child: Text("SB",
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 1))),
              ),
              const SizedBox(height: 14),
              const Text("SuperBett",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900,
                    color: Color(0xFF1A237E), letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text("Panel Administrativo",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500, letterSpacing: 0.8, fontWeight: FontWeight.w500)),
            ]),
          ),

          // ── Formulario
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: AnimatedBuilder(
              animation: _shakeAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(_hasError ? _shakeAnim.value : 0, 0),
                child: child,
              ),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [BoxShadow(color: Color(0x0C000000), blurRadius: 24, offset: Offset(0, 8))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Iniciar sesión",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 4),
                  Text("Ingresa tus credenciales para continuar",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                  const SizedBox(height: 28),

                  // Campo usuario
                  _label("Usuario"),
                  const SizedBox(height: 6),
                  _campo(
                    controller: _userCtrl,
                    focusNode: _userFocus,
                    hint: "nombre_usuario",
                    icon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _passFocus.requestFocus(),
                  ),
                  const SizedBox(height: 18),

                  // Campo contraseña
                  _label("Contraseña"),
                  const SizedBox(height: 6),
                  _campo(
                    controller: _passCtrl,
                    focusNode: _passFocus,
                    hint: "••••••••",
                    icon: Icons.lock_outline_rounded,
                    obscure: !_showPass,
                    suffix: IconButton(
                      onPressed: () => setState(() => _showPass = !_showPass),
                      icon: Icon(_showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.grey.shade400, size: 20),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _loading ? null : _login(),
                  ),
                  const SizedBox(height: 28),

                  // Botón ingresar
                  SizedBox(width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF9FA8DA),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _loading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text("Ingresar",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    )),

                  // Mensaje error
                  AnimatedSize(duration: const Duration(milliseconds: 200),
                    child: _msg.isEmpty ? const SizedBox.shrink()
                      : Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F0),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFFCDD2)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFE53935), size: 18),
                            const SizedBox(width: 10),
                            Expanded(child: Text(_msg,
                              style: const TextStyle(color: Color(0xFFB71C1C), fontSize: 13, fontWeight: FontWeight.w500))),
                          ]),
                        )),
                ]),
              ),
            ),
          )),

          // ── Footer
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text("© 2025 SuperBett. Acceso restringido.",
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          ),
        ]),
      ),
    );
  }

  Widget _label(String text) => Text(text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF374151)));

  Widget _campo({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputAction? textInputAction,
    void Function(String)? onSubmitted,
  }) {
    return Focus(
      focusNode: focusNode,
      child: Builder(builder: (ctx) {
        final focused = Focus.of(ctx).hasFocus;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: focused ? const Color(0xFF1A237E) : const Color(0xFFE5E7EB),
              width: focused ? 2 : 1.5),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.w400),
              prefixIcon: Icon(icon, color: focused ? const Color(0xFF1A237E) : Colors.grey.shade400, size: 20),
              suffixIcon: suffix,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        );
      }),
    );
  }
}
