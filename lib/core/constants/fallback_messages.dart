import 'dart:math';

import '../../domain/entities/agenda_summary.dart';

/// Banco local de mensajes de la mascota (sin internet).
/// En la Fase 7, Gemini genera los mensajes y este banco queda como
/// respaldo cuando no hay conexión o falla la API.
abstract final class FallbackMessages {
  static final Random _random = Random();

  static String randomFor(DayLoad load) {
    final list = _byLoad[load]!;
    return list[_random.nextInt(list.length)];
  }

  static String randomHurry() =>
      hurry[_random.nextInt(hurry.length)];

  static const Map<DayLoad, List<String>> _byLoad = {
    DayLoad.free: [
      'Hoy no hay nada agendado… día oficial de la siesta.',
      'Cero eventos. Te doy permiso de no hacer nada, yo haré lo mismo.',
      'Agenda vacía, mente tranquila. Aprovecha para soñar despierto.',
      'Hoy el plan es no tener plan. Mi favorito.',
      'Ni un solo evento a la vista. ¿Nos estiramos y ya?',
      'Día libre detectado. Repito: día libre detectado.',
      'Hoy tu única misión es descansar. Yo superviso desde mi cojín.',
      'Nada en la agenda. El universo te está diciendo algo: duerme.',
      'Silencio total en el calendario. Qué paz, ¿no?',
      'Sin eventos hoy. Si me buscas, estaré soñando.',
      'Hoy no corremos. Hoy flotamos.',
      'Agenda despejada, como cielo de vacaciones.',
    ],
    DayLoad.normal: [
      'Día tranquilo: lo justo para sentirte productivo sin despeinarte.',
      'Un par de cositas hoy. Tú puedes con eso y más.',
      'Agenda ligera. Perfecta para hacerlo todo con calma.',
      'Hoy pinta bien: poco que hacer y mucho tiempo para ti.',
      'Lo de hoy se resuelve rapidito, ya verás.',
      'Día equilibrado. Como a mí me gustan.',
      'Un poquito de deber y un muchote de tranquilidad.',
      'Hoy es de esos días amables. Disfrútalo.',
      'Tienes pendientes, pero nada que no puedas con una mano.',
      'Ritmo suave hoy. Yo te acompaño desde aquí.',
      'Poca cosa en la agenda: hazlo bien y luego celebramos.',
      'Hoy alcanza para todo, hasta para un antojito.',
    ],
    DayLoad.busy: [
      'Día moviducho. Respira hondo, vamos por partes.',
      'Varios eventos hoy. Tú tranquilo, yo llevo la cuenta.',
      'Hoy hay que ponerse las pilas. ¡Yo te animo desde aquí!',
      'Agenda llenita. Paso a paso y llegamos a todo.',
      'Hoy toca modo enfocado. ¡Tú puedes, humano!',
      'Un día cargado, pero nada imposible para nosotros.',
      'Mucho por hacer, pero míralo así: mañana será anécdota.',
      'Hoy el calendario está inquieto. Dómalo.',
      'Varios frentes abiertos hoy. Uno a la vez, campeón.',
      'Día intenso a la vista. Hidrátate, que yo vigilo la agenda.',
      '¡Arriba ese ánimo! El día está cargado pero tú más.',
      'Hoy corremos un poquito. Prometo siesta al final.',
    ],
    DayLoad.veryBusy: [
      'Día MUY cargado. Respira. Otra vez. Ahora sí: ¡a por todo!',
      'La agenda explotó hoy. Pero oye, nunca te he visto rendirte.',
      'Hoy es maratón. Yo pongo las porras, tú los pasos.',
      'Muchísimo por hacer. Prioriza, delega… y no te olvides de comer.',
      'Alerta de día intenso. Al final del día, siesta épica garantizada.',
      'El calendario está que arde. Tú, sereno como siempre.',
      'Hoy el día viene con turbo. Agárrate que vamos juntos.',
      'Cinco o más eventos… ¿quién te crees, superhéroe? Ah, sí, tú.',
      'Día pesado, pero recuerda: por la noche esto será una victoria.',
      'Modo supervivencia activado. Café en mano y a brillar.',
      'Hoy ni yo me atrevo a dormir. ¡Vamos con toda!',
      'Agenda al límite. Paso firme y sin pánico, que yo te cuido.',
    ],
  };

  /// Mensajes de apuro para la pantalla de alarma.
  static const List<String> hurry = [
    '¡Arriba! Que yo ya estoy despierta y eso es mucho decir…',
    '¿Vas a llegar tarde? Porque yo no pienso correr.',
    '¡Rápido, rápido! Luego duermes, humano.',
    'Te lo recuerdo ahora para que no me eches la culpa después.',
    '¡Es hora! Y no, cinco minutitos más no cuentan.',
    'Yo ya hice mi parte. Lo demás es cosa tuya.',
    '¡Vamos! Que el evento no se va a atender solo.',
    'Mueve esas patitas, que se hace tarde.',
    'Tic tac, tic tac… ese soy yo, apurándote con estilo.',
    'Si llegas tarde diré que no te avisé. Mentira: te avisé.',
  ];
}
