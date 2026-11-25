import 'dart:js_interop';

// Pitido corto con la API Web Audio: con los ojos cerrados no se ve la
// pantalla, y así se sabe cuándo abrirlos.

@JS('AudioContext')
extension type _Audio._(JSObject _) implements JSObject {
  external _Audio();
  external _Oscilador createOscillator();
  external _Ganancia createGain();
  external JSObject get destination;
  external double get currentTime;
}

extension type _Oscilador._(JSObject _) implements JSObject {
  external _Parametro get frequency;
  external void connect(JSObject destino);
  external void start(double cuando);
  external void stop(double cuando);
}

extension type _Ganancia._(JSObject _) implements JSObject {
  external _Parametro get gain;
  external void connect(JSObject destino);
}

extension type _Parametro._(JSObject _) implements JSObject {
  external set value(double v);
}

_Audio? _audio;

void pitido(double frecuencia) {
  try {
    final audio = _audio ??= _Audio();
    final oscilador = audio.createOscillator();
    final ganancia = audio.createGain();
    oscilador.frequency.value = frecuencia;
    ganancia.gain.value = 0.15;
    oscilador.connect(ganancia);
    ganancia.connect(audio.destination);
    oscilador.start(audio.currentTime);
    oscilador.stop(audio.currentTime + 0.18);
  } catch (_) {
    // Sin audio: queda el aviso visual y el del lector de pantalla.
  }
}
