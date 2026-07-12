(function () {
  'use strict';

  if (window.supabase && typeof window.supabase.createClient === 'function') return;

  function createClient(url, anonKey) {
    async function rpc(functionName, parameters) {
      try {
        const response = await fetch(url + '/rest/v1/rpc/' + encodeURIComponent(functionName), {
          method: 'POST',
          headers: {
            apikey: anonKey,
            Authorization: 'Bearer ' + anonKey,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(parameters || {})
        });
        const text = await response.text();
        let data = null;
        if (text) {
          try { data = JSON.parse(text); } catch (_) { data = text; }
        }
        if (!response.ok) {
          const message = data && (data.message || data.error_description || data.hint);
          return { data: null, error: new Error(message || 'Error de conexión (' + response.status + ').') };
        }
        return { data: data, error: null };
      } catch (error) {
        return { data: null, error: error };
      }
    }

    return {
      rpc: rpc,
      auth: {
        getSession: async function () { return { data: { session: null }, error: null }; },
        getUser: async function () { return { data: { user: null }, error: null }; },
        signOut: async function () { return { error: null }; }
      }
    };
  }

  window.supabase = { createClient: createClient };
})();
