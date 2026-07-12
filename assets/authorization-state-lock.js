(function () {
  'use strict';

  const client = window.OnboardAuth?.client ||
    window.supabase.createClient(
      window.ONBOARDFLOW_SUPABASE.url,
      window.ONBOARDFLOW_SUPABASE.anonKey
    );

  let authorized = false;
  let checking = false;
  let pollTimer = null;

  function showAuthorizedState() {
    const button = document.getElementById('joinButton');
    const countdown = document.getElementById('countdown');

    if (button) {
      if (button.disabled) button.disabled = false;
      if (button.textContent !== 'Entrar a la inducción') {
        button.textContent = 'Entrar a la inducción';
      }
    }
    if (countdown && countdown.textContent !== 'INGRESO AUTORIZADO') {
      countdown.textContent = 'INGRESO AUTORIZADO';
    }
  }

  function showWaitingState() {
    const button = document.getElementById('joinButton');
    if (!button) return;
    if (!button.disabled) button.disabled = true;
    if (button.textContent !== 'Esperando autorización del supervisor') {
      button.textContent = 'Esperando autorización del supervisor';
    }
  }

  async function checkAuthorization() {
    if (authorized || checking) return;

    const code = document.getElementById('accessCode')?.value.trim();
    const documentId = document.getElementById('documentId')?.value.trim();
    if (!code || !documentId) return;

    checking = true;
    try {
      const { data, error } = await client.rpc('of_candidate_current_waiting_status', {
        p_code: code,
        p_document_id: documentId
      });
      if (error) return;

      if (['present', 'late'].includes(data?.status)) {
        authorized = true;
        window.candidateAdmissionAuthorized = true;
        showAuthorizedState();
        if (pollTimer) {
          clearInterval(pollTimer);
          pollTimer = null;
        }
      } else {
        showWaitingState();
      }
    } finally {
      checking = false;
    }
  }

  window.enterJourney = async function () {
    await checkAuthorization();
    if (!authorized) {
      alert('El supervisor todavía no ha autorizado su ingreso en la sesión vigente.');
      return;
    }
    showAuthorizedState();
    go(6);
  };

  document.addEventListener('DOMContentLoaded', function () {
    checkAuthorization();
    pollTimer = setInterval(checkAuthorization, 2000);
  });
})();
