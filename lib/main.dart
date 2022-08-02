import 'package:flutter/material.dart';
import 'package:socket_io/socket_io.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final formKey = GlobalKey<FormState>();
  int _counter = 0;
  final io = Server();
  final List<Socket> clients = [];
  String msg = '';

  @override
  void initState() {
    super.initState();

    io.on('connection', (client) {
      if (client is Socket) {
        print('connection ${client.id}');
        clients.add(client);
        setState(() => _counter++);
        client.on('disconnect', (_) {
          if (clients.remove(client)) {
            setState(() => _counter--);
          }
          print('client disconnect ${client.id}');
        });
      }
    });
    io.listen(3131);
  }

  void sendMessage(String message) {
    for (var client in clients) {
      client.emit('message', message);
    }
  }

  @override
  void dispose() {
    io.close();
    super.dispose();
  }

  void _sendMsg() {
    if (formKey.currentState != null && formKey.currentState!.validate()) {
      formKey.currentState!.save();
      formKey.currentState!.reset();
      sendMessage(msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Socet.io server'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20, width: double.infinity),
              Text('Активных подключений: $_counter'),
              const SizedBox(height: 40),
              const Text('Введите команду "delete имя файла":'),
              const SizedBox(height: 20),
              Form(
                key: formKey,
                child: InputTextForm(
                  onSaved: (value) => msg = value,
                  onSubmit: (_) => _sendMsg(),
                  hintText: 'command',
                ),
              ),
              const SizedBox(height: 20),
              const Text('и нажмите кнопку отправить'),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _sendMsg,
        tooltip: 'Отправить',
        child: const Icon(Icons.send),
      ),
    );
  }
}

class InputTextForm extends StatelessWidget {
  final void Function(String value) onSaved;
  final void Function(String value) onSubmit;
  final String hintText;

  const InputTextForm({
    super.key,
    required this.onSaved,
    required this.onSubmit,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      autofocus: false,
      textCapitalization: TextCapitalization.none,
      textInputAction: TextInputAction.send,
      decoration: InputDecoration(
        border: const OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.black45,
          ),
        ),
        hintStyle: const TextStyle(
          color: Colors.grey,
        ),
        hintText: hintText,
      ),
      onSaved: (value) => onSaved(value ?? ''),
      onFieldSubmitted: (value) => onSubmit(value),
    );
  }
}
