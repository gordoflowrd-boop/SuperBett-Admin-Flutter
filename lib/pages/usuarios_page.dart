import 'package:flutter/material.dart';
import '../layout/app_layout.dart';
import '../services/bancas_service.dart';
import '../models/banca.dart';
import '../services/usuarios_service.dart';

class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});
  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {

  List<dynamic> _usuarios = [];
  bool _loading = true;
  String _error = "";
  String _idPropio = "";
  List<Banca> _bancas = [];

  @override
  void initState() {
    super.initState();
    _cargar();
    _cargarIdPropio();
    _cargarBancas();
  }

  Future<void> _cargarBancas() async {
    try {
      final b = await BancasService.obtenerBancas();
      if (mounted) setState(() => _bancas = b);
    } catch (_) {}
  }

  Future<void> _cargarIdPropio() async {
    final id = await UsuariosService.obtenerIdPropio();
    if (mounted) setState(() => _idPropio = id ?? '');
  }

  Future<void> _cargar() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = "";
    });

    try {
      final data = await UsuariosService.obtenerUsuarios();

      if (mounted) {
        setState(() {
          _usuarios = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  int get _totalUsuarios => _usuarios.length;
  int get _activos => _usuarios.where((u) => u['activo'] == true).length;
  int get _inactivos => _usuarios.where((u) => u['activo'] == false).length;
  int get _admins => _usuarios.where((u) => u['rol'] == 'admin').length;

  Widget _badgeRol(String? rol) {
    Color bg = const Color(0xFFE2E3E5);
    Color fg = const Color(0xFF383D41);

    switch (rol) {
      case 'admin':
        bg = const Color(0xFFD4EDDA);
        fg = const Color(0xFF155724);
        break;
      case 'central':
        bg = const Color(0xFFCCE5FF);
        fg = const Color(0xFF004085);
        break;
      case 'rifero':
        bg = const Color(0xFFFFF3CD);
        fg = const Color(0xFF856404);
        break;
      case 'vendedor':
        bg = const Color(0xFFE8D5FF);
        fg = const Color(0xFF6A0DAD);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(rol ?? '-', style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _badgeEstado(bool? activo) {
    final isActivo = activo == true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActivo ? const Color(0xFFD4EDDA) : const Color(0xFFF8D7DA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isActivo ? "Activo" : "Inactivo",
        style: TextStyle(
          color: isActivo ? const Color(0xFF155724) : const Color(0xFF721C24),
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _resumenChip(String label, String val, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(val, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _filaUsuario(Map<String, dynamic> u) {

    final nombreStr = (u['nombre'] ?? u['username'] ?? u['email'] ?? '?').toString();
    final inicial = nombreStr.isNotEmpty ? nombreStr[0].toUpperCase() : '?';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [

          CircleAvatar(
            backgroundColor: const Color(0xFF1A237E).withOpacity(0.1),
            child: Text(inicial, style: const TextStyle(color: Color(0xFF1A237E))),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(u['nombre'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(u['username'] ?? '-', style: TextStyle(color: Colors.grey.shade600)),
            ]),
          ),

          _badgeRol(u['rol']?.toString()),
          const SizedBox(width: 8),
          _badgeEstado(u['activo'] as bool?),

          const SizedBox(width: 8),

          InkWell(
            onTap: () => _mostrarFormulario(usuario: u),
            child: const Icon(Icons.edit, color: Color(0xFF1A237E)),
          )

        ]),
      ),
    );
  }

  Future<void> _mostrarFormulario({Map<String, dynamic>? usuario}) async {

    final esNuevo = usuario == null;

    final nombreCtrl = TextEditingController(text: usuario?['nombre'] ?? '');
    final emailCtrl = TextEditingController(text: usuario?['username'] ?? '');

    String rolSel = usuario?['rol'] ?? 'rifero';

    Set<String> paginasSel = {};

    final List<String> todasPaginas = [
      'bancas','venta','premios','reportes','usuarios',
      'mensajes','limites','configuracion','contabilidad','descargas'
    ];

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) {

        return StatefulBuilder(
          builder: (ctx,setModalState){

            return AlertDialog(

              title: Text(esNuevo ? "Nuevo Usuario" : "Editar Usuario"),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: "Nombre")),
                    TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Username")),

                    DropdownButtonFormField<String>(
                      value: rolSel,
                      decoration: const InputDecoration(labelText: "Rol"),
                      items: const [
                        DropdownMenuItem(value:'admin',child:Text("Admin")),
                        DropdownMenuItem(value:'central',child:Text("Central")),
                        DropdownMenuItem(value:'rifero',child:Text("Rifero")),
                        DropdownMenuItem(value:'vendedor',child:Text("Vendedor")),
                      ],
                      onChanged:(v)=>setModalState(()=>rolSel=v!),
                    ),

                    if(rolSel=='central'||rolSel=='rifero')...[
                      const SizedBox(height:10),
                      Wrap(
                        spacing:6,
                        children: todasPaginas.map((p){

                          final sel = paginasSel.contains(p);

                          return FilterChip(
                            label: Text(p),
                            selected: sel,
                            onSelected:(v){
                              setModalState(() {
                                if(v){ paginasSel.add(p); }
                                else{ paginasSel.remove(p); }
                              });
                            },
                          );

                        }).toList(),
                      )
                    ]

                  ],
                ),
              ),

              actions: [

                TextButton(
                  onPressed:()=>Navigator.pop(ctx),
                  child:const Text("Cancelar")
                ),

                ElevatedButton(

                  onPressed:() async{

                    Navigator.pop(ctx);

                    try{

                      if(esNuevo){

                        final nuevo = await UsuariosService.crearUsuarioConRespuesta(
                          username: emailCtrl.text,
                          nombre: nombreCtrl.text,
                          password: "123456",
                          rol: rolSel
                        );

                        final id = nuevo['usuario']?['id']?.toString();

                        if(id!=null && paginasSel.isNotEmpty){
                          await UsuariosService.guardarPaginas(id,paginasSel.toList());
                        }

                      }else{

                        final id = usuario!['id'].toString();

                        await UsuariosService.editarUsuario(
                          id,
                          nombre: nombreCtrl.text,
                          username: emailCtrl.text,
                          rol: rolSel
                        );

                        if(paginasSel.isNotEmpty){
                          await UsuariosService.guardarPaginas(id,paginasSel.toList());
                        }

                      }

                      await _cargar();

                    }catch(e){
                      if(mounted){
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content:Text("Error: $e"))
                        );
                      }
                    }

                  },

                  child:Text(esNuevo?"Crear":"Guardar")
                )

              ],

            );

          },
        );

      }
    );
  }

  @override
  Widget build(BuildContext context) {

    return AppLayout(
      selectedIndex: 6,
      child: Column(
        children: [

          Container(
            color: const Color(0xFF1A237E),
            padding: const EdgeInsets.all(16),
            child: Row(children:[
              const Expanded(
                child: Text("Usuarios",
                style:TextStyle(color:Colors.white,fontSize:17,fontWeight:FontWeight.bold))
              ),
              IconButton(icon:const Icon(Icons.refresh,color:Colors.white),onPressed:_cargar)
            ])
          ),

          Expanded(
            child: _loading
              ? const Center(child:CircularProgressIndicator())
              : _error.isNotEmpty
                ? Center(child:Text(_error,style:const TextStyle(color:Colors.red)))
                : ListView.builder(
                    itemCount:_usuarios.length,
                    itemBuilder:(_,i)=>_filaUsuario(_usuarios[i] as Map<String,dynamic>)
                  )
          )

        ],
      )
    );

  }
}