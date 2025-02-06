import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

//Merupakan StatelessWidget, yang berarti tidak memiliki state yang berubah.
class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key})
      : super(
            key:
                key); //super(key: key);: Konstruktor untuk kelas ini, menerima parameter opsional key.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //scaffold : Struktur dasar visual di Flutter yang menyediakan struktur layout dasar untuk aplikasi.
      body: Center(
        //Center: Widget untuk menempatkan konten di tengah layar.
        child: SvgPicture.asset(
          //SvgPicture.asset: Widget dari pustaka flutter_svg untuk menampilkan gambar SVG dari path yang diberikan (assets/logo_splash_screen.svg).
          'assets/logo_splash_screen.svg', // Path ke file SVG
          width: 125,
          height: 125,
        ),
      ),
    );
  }
}
