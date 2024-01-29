import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lens/main.dart';
import 'package:share/share.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:translator/translator.dart';

class EcranResultat extends StatelessWidget {
  final String texte;

  const EcranResultat({Key? key, required this.texte}) : super(key: key);

  Future<void> _copierDansPressePapiers(
      BuildContext context, String texte) async {
    await Clipboard.setData(ClipboardData(text: texte));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Texte copié dans le presse-papiers'.tr()), // Utilisez tr() ici
      ),
    );
  }

  Future<void> _partagerTexte(String texte) async {
    await Share.share(texte);
  }

  Future<String> _traduireTexte(String texte, BuildContext context) async {
    try {
      final locale = Locale('fr');
      final traducteur = GoogleTranslator();
      // final locale = Localizations.localeOf(context);
      Translation traduction =
          await traducteur.translate(texte, to: locale.languageCode);
      print("Texte traduit: ${traduction.text}");
      return traduction.text;
    } catch (e) {
      return "Erreur de traduction";
    }
  }

  Future<void> _faireQuelqueChoseLorsDuRejet(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Element rejeté'.tr()), // Utilisez tr() ici
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Resultat'.tr()),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => MonApplication()));
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Dismissible(
          key: const Key('result_dismissible_key'),
          child: SingleChildScrollView(
            child: Text(texte),
          ),
          background: Container(
            color: Color.fromARGB(255, 103, 175, 195),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            child: Icon(
              Icons.copy,
              color: Color.fromARGB(255, 222, 19, 19),
            ),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.endToStart) {
              await _copierDansPressePapiers(context, texte);
              return true;
            }
            return false;
          },
          onDismissed: (direction) {
            if (direction == DismissDirection.endToStart) {
              _faireQuelqueChoseLorsDuRejet(context);
            }
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          FloatingActionButton(
            onPressed: () async {
              final texteTraduit = await _traduireTexte(texte, context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EcranTraduction(
                    texteOriginal: texte,
                    texteTraduit: texteTraduit,
                  ),
                ),
              );
            },
            tooltip: 'Traduire le texte',
            child: const Icon(Icons.translate),
          ),
          FloatingActionButton(
            onPressed: () {
              _partagerTexte(texte);
            },
            tooltip: 'Partager le texte',
            child: const Icon(Icons.share),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: SizedBox.shrink(),
      ),
    );
  }
}

class EcranTraduction extends StatelessWidget {
  final String texteOriginal;
  final String texteTraduit;

  Future<void> _partagerTexte(String texteTraduit) async {
    await Share.share(texteTraduit);
  }

  const EcranTraduction({
    Key? key,
    required this.texteOriginal,
    required this.texteTraduit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Texte Traduit'.tr()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Texte Original:',
              style: TextStyle(
                color: Color.fromARGB(255, 135, 19, 71), // Couleur bleue
                fontWeight: FontWeight.bold, // Texte en gras
              ),
            ),
            const SizedBox(height: 16.0), // Saut de ligne
            Text(
              texteOriginal,
              style: TextStyle(
                color: const Color.fromARGB(255, 20, 21, 22), // Couleur bleue
                fontWeight: FontWeight.bold, // Texte en gras
              ),
            ),
            const SizedBox(height: 16.0), // Saut de ligne
            Text(
              'Texte Traduit:',
              style: TextStyle(
                color: Color.fromARGB(255, 229, 9, 9), // Couleur bleue
                fontWeight: FontWeight.bold, // Texte en gras
              ),
            ),
            const SizedBox(height: 16.0), // Saut de ligne
            Text(
              texteTraduit,
              style: TextStyle(
                color: Colors.blue, // Couleur bleue
                fontWeight: FontWeight.bold, // Texte en gras
              ),
            ),
            FloatingActionButton(
              onPressed: () {
                _partagerTexte(texteTraduit);
              },
              tooltip: 'Partager le texte',
              child: const Icon(Icons.share),
            ),
          ],
        ),
      ),
    );
  }
}
