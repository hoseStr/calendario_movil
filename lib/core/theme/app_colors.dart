import 'package:flutter/material.dart';

/// Paleta central de la app — estética onírica:
/// lavandas, lilas y azules brumosos con acentos pastel.
/// Ninguna pantalla debe usar colores hardcodeados.
abstract final class AppColors {
  // Marca: lavanda de ensueño con acento rosa bruma.
  static const Color seed = Color(0xFF8E7CC3); // lavanda
  static const Color accent = Color(0xFFF2A6C8); // rosa bruma

  // Fondos base (los degradados viven en app_gradients.dart).
  static const Color mistLight = Color(0xFFF6F3FB); // niebla clara
  static const Color nightDark = Color(0xFF17132A); // noche violeta

  // Colores de categorías de eventos (pasteles oníricos, Fase 4).
  // Tonos repartidos por el círculo cromático para diferenciarse bien
  // manteniendo la estética brumosa de la app.
  static const List<Color> eventCategories = [
    Color(0xFFA99BE0), // lavanda — general
    Color(0xFF8FD8CE), // menta bruma — trabajo/estudio
    Color(0xFFF2A6C8), // rosa bruma — personal
    Color(0xFFF4B8A0), // durazno — importante
    Color(0xFF9EC9F0), // azul cielo — salud
    Color(0xFFE8C9F0), // lila pálido — ocio
    Color(0xFFF0DA9A), // mantequilla — amarillo suave
    Color(0xFFB4D9A0), // verde salvia — naturaleza
    Color(0xFFF29B9B), // coral bruma — urgente
    Color(0xFF9DA8EA), // periwinkle — azul violáceo
  ];
}
