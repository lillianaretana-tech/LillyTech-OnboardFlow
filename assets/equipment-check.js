(function () {
  'use strict';
  const set = (id, text) => {
    const element = document.getElementById(id);
    if (element) element.textContent = text;
  };

  async function cameraWorks(stream) {
    const track = stream.getVideoTracks()[0];
    if (!track || track.readyState !== 'live' || !track.enabled || track.muted) return false;
    const video = document.createElement('video');
    video.muted = true;
    video.playsInline = true;
    video.srcObject = new MediaStream([track]);
    try {
      await video.play();
      await new Promise(resolve => setTimeout(resolve, 700));
      return video.videoWidth > 0 && video.videoHeight > 0;
    } catch (_) {
      return false;
    } finally {
      video.pause();
      video.srcObject = null;
    }
  }

  function microphoneAvailable(stream) {
    const track = stream.getAudioTracks()[0];
    return Boolean(track && track.readyState === 'live' && track.enabled && !track.muted);
  }

  window.runEquipmentCheck = async function () {
    const next = document.getElementById('equipmentNext');
    const message = document.getElementById('equipmentMessage');
    next.disabled = true;
    set('internetStatus', navigator.onLine ? 'Con conexión' : 'Sin conexión');
    set('cameraStatus', 'Probando...');
    set('micStatus', 'Probando...');
    set('audioStatus', 'Requiere prueba manual');
    message.className = 'alert info';
    message.classList.remove('hidden');
    message.textContent = 'Autorice el uso de cámara y micrófono.';

    let stream;
    try {
      if (!navigator.mediaDevices?.getUserMedia) throw new Error('El navegador no permite comprobar dispositivos.');
      stream = await navigator.mediaDevices.getUserMedia({ video: true, audio: true });
      const camera = await cameraWorks(stream);
      const microphone = microphoneAvailable(stream);
      set('cameraStatus', camera ? 'Imagen comprobada' : 'Sin imagen');
      set('micStatus', microphone ? 'Micrófono disponible' : 'No disponible');
      set('waitingCameraStatus', camera ? 'Imagen comprobada' : 'Sin imagen');
      set('waitingMicStatus', microphone ? 'Micrófono disponible' : 'No disponible');

      if (camera && microphone && navigator.onLine) {
        message.className = 'alert ok';
        message.textContent = 'Cámara y micrófono disponibles. Puede continuar.';
        next.disabled = false;
      } else {
        message.className = 'alert bad';
        message.textContent = 'No fue posible confirmar todos los dispositivos. Revise permisos y conexión.';
      }
    } catch (error) {
      set('cameraStatus', 'No disponible');
      set('micStatus', 'No disponible');
      set('waitingCameraStatus', 'No disponible');
      set('waitingMicStatus', 'No disponible');
      message.className = 'alert bad';
      message.textContent = 'No fue posible acceder a cámara y micrófono: ' + (error.name === 'NotAllowedError' ? 'permiso bloqueado.' : error.message);
    } finally {
      stream?.getTracks().forEach(track => track.stop());
    }
  };
})();
