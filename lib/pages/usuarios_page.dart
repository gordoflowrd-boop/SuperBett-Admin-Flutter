import 'package:flutter/material.dart';
import '../layout/app_layout.dart';
import '../services/bancas_service.dart';
import '../services/usuarios_service.dart';
import '../models/banca.dart';

class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage>{

  List<dynamic> _usuarios=[];
  List<Banca> _bancas=[];

  bool _loading=true;
  String _error="";
  String _idPropio="";

  @override
  void initState(){
    super.initState();
    _cargar();
    _cargarBancas();
    _cargarIdPropio();
  }

  Future<void> _cargar() async{

    try{

      final data = await UsuariosService.obtenerUsuarios();

      if(mounted){
        setState(() {
          _usuarios=data;
          _loading=false;
        });
      }

    }catch(e){

      if(mounted){
        setState(() {
          _error=e.toString();
          _loading=false;
        });
      }

    }

  }

  Future<void> _cargarBancas() async{

    try{
      final b = await BancasService.obtenerBancas();

      if(mounted){
        setState(()=>_bancas=b);
      }

    }catch(_){}
  }

  Future<void> _cargarIdPropio() async{

    final id = await UsuariosService.obtenerIdPropio();

    if(mounted){
      setState(()=>_idPropio=id??'');
    }

  }

  Widget _filaUsuario(Map<String,dynamic> u){

    final nombre = (u['nombre']??'?').toString();

    return ListTile(

      title:Text(nombre),

      subtitle:Text(u['username']??''),

      trailing:IconButton(
        icon:const Icon(Icons.edit),
        onPressed:()=>_mostrarFormulario(usuario:u),
      ),

    );
  }

  Future<void> _mostrarFormulario({Map<String,dynamic>? usuario}) async{

    final esNuevo = usuario==null;

    final nombreCtrl = TextEditingController(text:usuario?['nombre']??'');
    final usernameCtrl = TextEditingController(text:usuario?['username']??'');

    String rolSel = usuario?['rol'] ?? 'rifero';

    Set<String> paginasSel={};

    final paginas=[
      'bancas','venta','premios','reportes','usuarios',
      'mensajes','limites','configuracion','contabilidad','descargas'
    ];

    if(!esNuevo){

      final id = usuario!['id'].toString();

      try{

        final pags = await UsuariosService.obtenerPaginas(id);

        paginasSel = Set<String>.from(pags);

      }catch(_){}
    }

    await showDialog(

      context:context,

      builder:(ctx){

        return StatefulBuilder(

          builder:(ctx,setModal){

            return AlertDialog(

              title:Text(esNuevo?"Nuevo Usuario":"Editar Usuario"),

              content:SingleChildScrollView(

                child:Column(

                  children:[

                    TextField(
                      controller:nombreCtrl,
                      decoration:const InputDecoration(labelText:"Nombre"),
                    ),

                    TextField(
                      controller:usernameCtrl,
                      decoration:const InputDecoration(labelText:"Username"),
                    ),

                    DropdownButtonFormField<String>(

                      value:rolSel,

                      items:const[
                        DropdownMenuItem(value:'admin',child:Text("Admin")),
                        DropdownMenuItem(value:'central',child:Text("Central")),
                        DropdownMenuItem(value:'rifero',child:Text("Rifero")),
                        DropdownMenuItem(value:'vendedor',child:Text("Vendedor")),
                      ],

                      onChanged:(v){
                        setModal(()=>rolSel=v!);
                      },

                    ),

                    if(rolSel=='central'||rolSel=='rifero')...[
                      const SizedBox(height:10),

                      Wrap(

                        spacing:6,

                        children:paginas.map((p){

                          final sel = paginasSel.contains(p);

                          return FilterChip(

                            label:Text(p),

                            selected:sel,

                            onSelected:(v){

                              setModal(() {

                                if(v){
                                  paginasSel.add(p);
                                }else{
                                  paginasSel.remove(p);
                                }

                              });

                            },

                          );

                        }).toList(),

                      )

                    ]

                  ],

                ),

              ),

              actions:[

                TextButton(
                  onPressed:()=>Navigator.pop(ctx),
                  child:const Text("Cancelar")
                ),

                ElevatedButton(

                  child:const Text("Guardar"),

                  onPressed:() async{

                    Navigator.pop(ctx);

                    try{

                      if(esNuevo){

                        final nuevo = await UsuariosService.crearUsuarioConRespuesta(
                          username:usernameCtrl.text,
                          password:"123456",
                          nombre:nombreCtrl.text,
                          rol:rolSel
                        );

                        final id = nuevo['usuario']?['id']?.toString();

                        if(id!=null){

                          await UsuariosService.guardarPaginas(
                            id,
                            paginasSel.toList()
                          );

                        }

                      }else{

                        final id = usuario!['id'].toString();

                        await UsuariosService.editarUsuario(
                          id,
                          nombre:nombreCtrl.text,
                          username:usernameCtrl.text,
                          rol:rolSel
                        );

                        await UsuariosService.guardarPaginas(
                          id,
                          paginasSel.toList()
                        );

                      }

                      await _cargar();

                    }catch(e){

                      if(mounted){

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content:Text(e.toString()))
                        );

                      }

                    }

                  }

                )

              ],

            );

          },

        );

      },

    );

  }

  @override
  Widget build(BuildContext context){

    return AppLayout(

      selectedIndex:6,

      child:_loading
        ?const Center(child:CircularProgressIndicator())
        :ListView.builder(
            itemCount:_usuarios.length,
            itemBuilder:(_,i)=>_filaUsuario(_usuarios[i])
          )

    );

  }

}