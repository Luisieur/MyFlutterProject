import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'result_screen.dart';

void main() {
  runApp(const MonApplication());
}

class MonApplication extends StatelessWidget {
  const MonApplication({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reconnaissance de texte avec Flutter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const EcranPrincipal(),
    );
  }
}

final textRecognizer = TextRecognizer();

class EcranPrincipal extends StatefulWidget {
  const EcranPrincipal({Key? key}) : super(key: key);

  @override
  State<EcranPrincipal> createState() => _EtatEcranPrincipal();
}

class _EtatEcranPrincipal extends State<EcranPrincipal>
    with WidgetsBindingObserver {
  bool _isAutorisationCameraAccordee = false;
  late final Future<void> _future;
  CameraController? _cameraController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _future = _initialiserApplication();
  }

  // Initialiser l'application, demander l'autorisation de la caméra, et initialiser la caméra si l'autorisation est accordée
  Future<void> _initialiserApplication() async {
    await _demanderAutorisationCamera();
    if (_isAutorisationCameraAccordee) {
      await _initialiserCamera();
    }
  }

  // Demander l'autorisation d'accéder à la caméra
  Future<void> _demanderAutorisationCamera() async {
    final status = await Permission.camera.request();
    setState(() {
      _isAutorisationCameraAccordee = status == PermissionStatus.granted;
    });
  }

  // Initialiser la caméra en sélectionnant la première caméra arrière disponible
  Future<void> _initialiserCamera() async {
    final cameras = await availableCameras();
    _initialiserControleurCamera(cameras);
  }

  // Initialiser le contrôleur de caméra avec la première caméra arrière disponible
  void _initialiserControleurCamera(List<CameraDescription> cameras) {
    if (_cameraController != null || cameras.isEmpty) {
      return;
    }

    // Sélectionner la première caméra arrière.
    final CameraDescription camera = cameras.firstWhere(
      (current) => current.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      camera,
      ResolutionPreset.max,
      enableAudio: false,
    );

    _cameraController!.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  // Démarrer la caméra si elle est initialisée
  Future<void> _demarrerCamera() async {
    if (_cameraController != null && !_cameraController!.value.isInitialized) {
      await _cameraController!.initialize();
    }

    if (_cameraController != null && _cameraController!.value.isInitialized) {
      (_cameraController!.description);
    }
  }

  // Arrêter la caméra
  void _arreterCamera() {
    if (_cameraController != null) {
      _cameraController!.dispose();
    }
  }

  // Observer le changement d'état de l'application et agir en conséquence (arrêter ou démarrer la caméra)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _arreterCamera();
    } else if (state == AppLifecycleState.resumed) {
      _demarrerCamera();
    }
  }

  // Libérer les ressources à la fermeture de l'écran
  @override
  void dispose() {
    _arreterCamera();
    textRecognizer.close();
    super.dispose();
    setState(() {});
  }

  // Obtenir une image à partir de la galerie
  Future<void> _obtenirImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final inputImage = InputImage.fromFile(file);
      final recognizedText = await textRecognizer.processImage(inputImage);

      final navigator = Navigator.of(context);
      await navigator.pushReplacement(
        MaterialPageRoute(
          builder: (BuildContext context) =>
              EcranResultat(texte: recognizedText.text),
        ),
      );
    } else {
      print('Aucune image sélectionnée.');
    }
  }

  // Scanner une image en utilisant la caméra
  Future<void> _scannerImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    final navigator = Navigator.of(context);

    try {
      final pictureFile = await _cameraController!.takePicture();

      final file = File(pictureFile.path);
      final inputImage = InputImage.fromFile(file);
      final recognizedText = await textRecognizer.processImage(inputImage);

      await navigator.pushReplacement(
        MaterialPageRoute(
          builder: (BuildContext context) =>
              EcranResultat(texte: recognizedText.text),
        ),
      );
    } catch (e) {
      // Afficher une notification en cas d'erreur lors de la numérisation du texte
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Une erreur s'est produite lors de la numérisation du texte"),
        ),
      );
    }
  }

  // Construire l'interface utilisateur en fonction de l'état de l'application
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        return Stack(
          children: [
            // Afficher la prévisualisation de la caméra si l'autorisation est accordée
            if (_isAutorisationCameraAccordee)
              FutureBuilder<List<CameraDescription>>(
                future: availableCameras(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    _initialiserControleurCamera(snapshot.data!);

                    return Center(child: CameraPreview(_cameraController!));
                  } else {
                    return const LinearProgressIndicator();
                  }
                },
              ),
            Scaffold(
              appBar: AppBar(
                title: const Text('Lens Text'),
                backgroundColor: Colors.cyan,
              ),
              backgroundColor:
                  _isAutorisationCameraAccordee ? Colors.transparent : null,
              body: _isAutorisationCameraAccordee
                  ? Column(
                      children: [
                        Expanded(
                          child: Container(),
                        ),
                        Container(
                          padding: const EdgeInsets.only(bottom: 30.0),
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 5,
                              horizontal: 5,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Bouton pour scanner une image en utilisant la caméra
                                FloatingActionButton(
                                  onPressed: _scannerImage,
                                  child: Icon(Icons.camera_alt),
                                  tooltip: 'Capturer une image',
                                ),
                                // Bouton pour obtenir une image à partir de la galerie
                                FloatingActionButton(
                                  onPressed: _obtenirImage,
                                  child: Icon(Icons.photo_library),
                                  tooltip: 'Ouvrir la galerie',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Container(
                        padding: const EdgeInsets.only(left: 24.0, right: 24.0),
                        child: const Text(
                          "Autorisation de la caméra refusée",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
