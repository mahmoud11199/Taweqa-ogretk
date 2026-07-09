(function() {
var STORAGE_KEY = 'taweqe_sb_session';
var _authCbs = [];

function loadSession() {
  try { var d = JSON.parse(localStorage.getItem(STORAGE_KEY)); if (d && d.access_token && d.expires_at > Date.now() / 1000) return d; } catch(e) { console.error('Session load error:', e); }
  return null;
}
function saveSession(s) {
  if (!s) return;
  try {
    s.expires_at = s.expires_at || (Date.now() / 1000 + (s.expires_in || 3600));
    localStorage.setItem(STORAGE_KEY, JSON.stringify(s));
  } catch(e) { console.error('Session save error:', e); }
}
function clearSession() {
  try { localStorage.removeItem(STORAGE_KEY); } catch(e) { console.error('Session clear error:', e); }
}

function sbFetch(url, opts) {
  return fetch(url, opts).then(function(r) {
    return r.text().then(function(text) {
      var data;
      try { data = JSON.parse(text); } catch(e) { data = text; }
      return { data: data, error: r.ok ? null : data, status: r.status };
    });
  }).catch(function(e) {
    return { data: null, error: e, status: 0 };
  });
}

function makeAuth(url, anonKey) {
  var authUrl = url + '/auth/v1';
  var gh = { apikey: anonKey, 'Content-Type': 'application/json' };
  function ah() {
    var s = loadSession();
    var t = {};
    if (s && s.access_token) t.Authorization = 'Bearer ' + s.access_token;
    return t;
  }
  function notifyAuth(event, session) {
    _authCbs.forEach(function(cb) { try { cb(event, session); } catch(e) { console.error('Auth callback error:', e); } });
  }
  function handleResp(resp) {
    if (resp.error) return { data: null, error: resp.error };
    if (resp.data && resp.data.access_token) {
      saveSession(resp.data);
      notifyAuth('SIGNED_IN', resp.data);
    }
    return { data: resp.data, error: null };
  }
  return {
    signInWithPassword: function(creds) {
      return sbFetch(authUrl + '/token?grant_type=password', {
        method: 'POST', headers: gh,
        body: JSON.stringify({ email: creds.email, password: creds.password })
      }).then(handleResp);
    },
    signUp: function(creds) {
      return sbFetch(authUrl + '/signup', {
        method: 'POST', headers: gh,
        body: JSON.stringify({ email: creds.email, password: creds.password, data: creds.options && creds.options.data })
      }).then(handleResp);
    },
    signOut: function() {
      var s = loadSession();
      clearSession();
      notifyAuth('SIGNED_OUT', null);
      if (s && s.access_token) {
        return sbFetch(authUrl + '/logout', {
          method: 'POST', headers: Object.assign({}, gh, { Authorization: 'Bearer ' + s.access_token })
        }).then(function() { return { error: null }; });
      }
      return Promise.resolve({ error: null });
    },
    getSession: function() {
      var s = loadSession();
      if (s && s.user) return Promise.resolve({ data: { session: s }, error: null });
      if (s) return sbFetch(authUrl + '/user', { headers: Object.assign({}, gh, { Authorization: 'Bearer ' + s.access_token }) }).then(function(r) {
        if (r.data && !r.error) { s.user = r.data; saveSession(s); return { data: { session: s }, error: null }; }
        return { data: { session: null }, error: null };
      });
      return Promise.resolve({ data: { session: null }, error: null });
    },
    setSession: function(params) {
      if (!params.access_token || !params.refresh_token) return Promise.resolve({ data: { user: null, session: null }, error: null });
      return sbFetch(authUrl + '/token?grant_type=refresh_token', {
        method: 'POST', headers: gh,
        body: JSON.stringify({ refresh_token: params.refresh_token })
      }).then(function(r) {
        if (r.data && !r.error) { saveSession(r.data); return { data: { user: r.data.user, session: r.data }, error: null }; }
        return { data: { user: null, session: null }, error: null };
      });
    },
    updateUser: function(attrs) {
      var s = loadSession();
      if (!s) return Promise.resolve({ data: null, error: { message: 'No session' } });
      return sbFetch(authUrl + '/user', {
        method: 'PUT', headers: Object.assign({}, gh, { Authorization: 'Bearer ' + s.access_token }),
        body: JSON.stringify(attrs)
      }).then(function(r) {
        if (r.data && !r.error) { s.user = r.data; saveSession(s); return { data: { user: r.data }, error: null }; }
        return { data: null, error: r.data || r.error };
      });
    },
    resetPasswordForEmail: function(email, opts) {
      return sbFetch(authUrl + '/recover', {
        method: 'POST', headers: gh,
        body: JSON.stringify({ email: email, redirect_to: opts && opts.redirectTo })
      }).then(function(r) { return { data: r.data, error: r.error }; });
    },
    verifyOtp: function(params) {
      return sbFetch(authUrl + '/verify', {
        method: 'POST', headers: gh,
        body: JSON.stringify(params)
      }).then(handleResp);
    },
    onAuthStateChanged: function(cb) {
      _authCbs.push(cb);
      var session = loadSession();
      if (session) setTimeout(function() { cb('SIGNED_IN', session); }, 0);
      return { data: { subscription: { id: 'lite_' + Date.now(), unsubscribe: function() { var i = _authCbs.indexOf(cb); if (i >= 0) _authCbs.splice(i, 1); } } } };
    }
  };
}

function makeQueryBuilder(url, anonKey, table, method, body, opts) {
  var query = {
    method: method || null,
    selectCols: '*',
    filters: [],
    orderBy: null,
    orderAsc: true,
    limitCount: null,
    singleResult: false,
    maybeSingleResult: false,
    body: body,
    headers: {}
  };
  if (opts) Object.assign(query.headers, opts.headers);

  var builder = {
    select: function(cols) { query.selectCols = cols || '*'; if (!query.method) query.method = 'GET'; return builder; },
    eq: function(col, val) { query.filters.push({ col: col, op: 'eq', val: val }); return builder; },
    neq: function(col, val) { query.filters.push({ col: col, op: 'neq', val: val }); return builder; },
    in: function(col, vals) { query.filters.push({ col: col, op: 'in', val: vals }); return builder; },
    order: function(col, dirs) { query.orderBy = col; query.orderAsc = !dirs || dirs.ascending !== false; return builder; },
    limit: function(n) { query.limitCount = n; return builder; },
    single: function() { query.singleResult = true; return builder; },
    maybeSingle: function() { query.maybeSingleResult = true; return builder; },
    then: function(fn) {
      return execQuery().then(fn);
    },
    _exec: function() {
      return execQuery();
    }
  };

  function getAuthHeaders() {
    var s = loadSession();
    var h = { apikey: anonKey, 'Content-Type': 'application/json', Prefer: 'return=representation' };
    if (s && s.access_token) h.Authorization = 'Bearer ' + s.access_token;
    Object.assign(h, query.headers);
    return h;
  }

  function execQuery() {
    var tableUrl = url + '/rest/v1/' + table;
    if (!query.method || query.method === 'GET') {
      var params = 'select=' + encodeURIComponent(query.selectCols);
      query.filters.forEach(function(f) {
        if (f.op === 'in') {
          params += '&' + encodeURIComponent(f.col) + '=in.(' + f.val.map(function(v) { return encodeURIComponent(v); }).join(',') + ')';
        } else {
          params += '&' + encodeURIComponent(f.col) + '=' + f.op + '.' + encodeURIComponent(String(f.val));
        }
      });
      if (query.orderBy) params += '&order=' + encodeURIComponent(query.orderBy) + (query.orderAsc ? '.asc' : '.desc');
      if (query.singleResult || query.maybeSingleResult) { if (!query.limitCount) params += '&limit=1'; }
      if (query.limitCount) params += '&limit=' + query.limitCount;
      var h = getAuthHeaders();
      if (query.singleResult) h.Accept = 'application/vnd.pgrst.object+json';
      if (query.maybeSingleResult) h.Accept = 'application/vnd.pgrst.object+json';
      return sbFetch(tableUrl + '?' + params, { method: 'GET', headers: h }).then(function(r) {
        var d = r.data;
        if (d && (query.singleResult || query.maybeSingleResult)) {
          if (Array.isArray(d)) d = d.length > 0 ? d[0] : null;
        }
        return { data: d, error: r.error, count: null, status: r.status, statusText: r.error ? String(r.error) : '' };
      });
    }
    if (query.method === 'POST') {
      var h = getAuthHeaders();
      var url2 = tableUrl;
      if (query.selectCols && query.selectCols !== '*') url2 += '?select=' + encodeURIComponent(query.selectCols);
      return sbFetch(url2, { method: 'POST', headers: h, body: JSON.stringify(query.body) }).then(function(r) {
        var d = r.data;
        if (d && query.singleResult) {
          if (Array.isArray(d)) d = d.length > 0 ? d[0] : null;
        }
        return { data: d, error: r.error };
      });
    }
    if (query.method === 'PATCH') {
      var h = getAuthHeaders();
      var url2 = tableUrl + '?';
      query.filters.forEach(function(f) {
        url2 += encodeURIComponent(f.col) + '=' + f.op + '.' + encodeURIComponent(String(f.val)) + '&';
      });
      return sbFetch(url2.replace(/&$/, ''), { method: 'PATCH', headers: h, body: JSON.stringify(query.body) }).then(function(r) {
        return { data: r.data, error: r.error };
      });
    }
    return Promise.resolve({ data: null, error: { message: 'Unknown method' } });
  }

  return builder;
}

window.__supaLiteCreateClient = function(url, anonKey) {

  function ensureHeaders() {
    return { apikey: anonKey, 'Content-Type': 'application/json' };
  }

  var client = {
    auth: makeAuth(url, anonKey),
    from: function(table) {
      var b = makeQueryBuilder(url, anonKey, table);
      b.upsert = function(data) {
        var s = loadSession();
        var h = { apikey: anonKey, 'Content-Type': 'application/json', Prefer: 'resolution=merge-duplicates' };
        if (s && s.access_token) h.Authorization = 'Bearer ' + s.access_token;
        var tableUrl = url + '/rest/v1/' + table;
        return sbFetch(tableUrl, { method: 'POST', headers: h, body: JSON.stringify(data) }).then(function(r) {
          return { data: r.data, error: r.error };
        });
      };
      b.insert = function(data) {
        return makeQueryBuilder(url, anonKey, table, 'POST', data);
      };
      b.update = function(data) {
        var s = loadSession();
        var h = { apikey: anonKey, 'Content-Type': 'application/json', Prefer: 'return=representation' };
        if (s && s.access_token) h.Authorization = 'Bearer ' + s.access_token;
        var queryBuilder = makeQueryBuilder(url, anonKey, table, 'PATCH', data, { headers: h });
        return queryBuilder;
      };
      return b;
    },
    rpc: function(fnName, params) {
      var s = loadSession();
      var h = { apikey: anonKey, 'Content-Type': 'application/json' };
      if (s && s.access_token) h.Authorization = 'Bearer ' + s.access_token;
      return sbFetch(url + '/rest/v1/rpc/' + fnName, { method: 'POST', headers: h, body: JSON.stringify(params || {}) }).then(function(r) {
        return { data: r.data, error: r.error };
      });
    },
    functions: {
      invoke: function(name, opts) {
        var s = loadSession();
        var h = { apikey: anonKey, 'Content-Type': 'application/json' };
        if (s && s.access_token) h.Authorization = 'Bearer ' + s.access_token;
        return sbFetch(url + '/functions/v1/' + name, { method: 'POST', headers: h, body: opts && opts.body ? JSON.stringify(opts.body) : null }).then(function(r) {
          return { data: r.data, error: r.error };
        });
      }
    },
    // ======================== REALTIME (WebSocket) ========================
    channel: function(name) {
      if (!_rtChannels) _rtChannels = {};
      if (!_rtChannels[name]) {
        _rtChannels[name] = { name: name, cbs: [], configs: [], statusCb: null, topic: null, joinRef: null, joined: false };
      }
      var store = _rtChannels[name];
      var api = {
        _rtName: name,
        on: function(evType, cfg, cb) {
          if (evType === 'postgres_changes' && cfg && cb) {
            store.configs.push(cfg);
            store.cbs.push(cb);
          }
          return api;
        },
        subscribe: function(cb) {
          store.statusCb = cb || null;
          _rtConnect(url, anonKey);
          if (store.configs.length === 0 && cb) setTimeout(function() { cb('SUBSCRIBED'); }, 0);
          return { unsubscribe: function() { _rtLeave(name); } };
        }
      };
      return api;
    },
    getChannels: function() {
      if (!_rtChannels) return [];
      return Object.keys(_rtChannels).map(function(k) { var s = _rtChannels[k]; return { topic: s.topic, configs: s.configs }; });
    },
    removeChannel: function(ch) {
      if (ch && ch._rtName && _rtChannels && _rtChannels[ch._rtName]) { _rtLeave(ch._rtName); }
    },
    removeAllChannels: function() {
      if (!_rtChannels) return;
      for (var k in _rtChannels) { _rtLeave(k); }
      _rtChannels = {}; _rtCloseWs();
    }
  };

  return client;
};

// ======================== REALTIME SHARED STATE ========================
var _rtWs = null, _rtGen = 0, _rtMsgRef = 1, _rtChannels = null, _rtHbTimer = null, _rtReconnTimer = null;

function _rtGetWsUrl(url, anonKey) {
  return url.replace('https://', 'wss://') + '/realtime/v1/websocket?apikey=' + encodeURIComponent(anonKey) + '&vsn=1.0.0';
}

function _rtConnect(url, anonKey) {
  if (_rtWs && (_rtWs.readyState === WebSocket.OPEN || _rtWs.readyState === WebSocket.CONNECTING)) return;
  var gen = ++_rtGen;
  try { _rtWs = new WebSocket(_rtGetWsUrl(url, anonKey)); } catch(e) { return; }
  _rtWs.onopen = function() {
    if (gen !== _rtGen) return;
    for (var k in _rtChannels) { _rtSendJoins(k); }
    _rtStartHb();
  };
  _rtWs.onmessage = function(ev) {
    if (gen !== _rtGen) return;
    try {
      var m = JSON.parse(ev.data);
      if (m.event === 'postgres_changes' && m.payload && m.payload.data) {
        var t = m.topic;
        for (var k in _rtChannels) {
          var s = _rtChannels[k];
          if (s.topic === t) {
            s.cbs.forEach(function(cb) { try { cb(m.payload.data); } catch(e) { console.error('Realtime cb error:', e); } });
          }
        }
      } else if (m.event === 'phx_reply' && m.payload) {
        for (var k in _rtChannels) {
          var s = _rtChannels[k];
          if (s.joinRef === m.join_ref) {
            if (m.payload.status === 'ok') { s.joined = true; if (s.statusCb) s.statusCb('SUBSCRIBED'); }
            else { if (s.statusCb) s.statusCb('CHANNEL_ERROR'); }
          }
        }
      }
    } catch(e) { /* ignore parse errors */ }
  };
  _rtWs.onclose = function() {
    if (gen !== _rtGen) return;
    _rtStopHb();
    for (var k in _rtChannels) {
      var s = _rtChannels[k]; s.joined = false;
      if (s.statusCb) s.statusCb('CLOSED');
    }
    if (_rtReconnTimer) clearTimeout(_rtReconnTimer);
    _rtReconnTimer = setTimeout(function() { _rtReconnTimer = null; _rtConnect(url, anonKey); }, 3000);
  };
}

function _rtStartHb() {
  _rtStopHb();
  _rtHbTimer = setInterval(function() {
    if (_rtWs && _rtWs.readyState === WebSocket.OPEN) {
      _rtWs.send(JSON.stringify({ join_ref: null, ref: String(_rtMsgRef++), topic: 'phoenix', event: 'heartbeat', payload: {} }));
    }
  }, 30000);
}
function _rtStopHb() { if (_rtHbTimer) { clearInterval(_rtHbTimer); _rtHbTimer = null; } }

function _rtSendJoins(name) {
  var s = _rtChannels && _rtChannels[name];
  if (!s || !s.configs.length || !_rtWs || _rtWs.readyState !== WebSocket.OPEN) return;
  s.configs.forEach(function(cfg) {
    var ref = String(_rtMsgRef++);
    var topic = 'realtime:' + (cfg.schema || 'public');
    s.topic = topic;
    s.joinRef = ref;
    _rtWs.send(JSON.stringify({
      join_ref: ref, ref: ref, topic: topic, event: 'phx_join',
      payload: { body: { event: cfg.event || '*', schema: cfg.schema || 'public', table: cfg.table || null, filter: cfg.filter || '' } }
    }));
  });
}

function _rtLeave(name) {
  var s = _rtChannels && _rtChannels[name];
  if (!s) return;
  if (_rtWs && _rtWs.readyState === WebSocket.OPEN) {
    s.configs.forEach(function(cfg) {
      var ref = String(_rtMsgRef++);
      _rtWs.send(JSON.stringify({
        join_ref: ref, ref: ref, topic: 'realtime:' + (cfg.schema || 'public'), event: 'phx_leave',
        payload: { body: {} }
      }));
    });
  }
  delete _rtChannels[name];
}

function _rtCloseWs() {
  _rtStopHb();
  if (_rtWs) { try { _rtWs.close(); } catch(e) {} _rtWs = null; }
  _rtGen++;
}

function getAuthHeaders(qb) {
  var s = loadSession();
  var h = { apikey: qb.apikey || '', 'Content-Type': 'application/json', Prefer: 'return=representation' };
  if (s && s.access_token) h.Authorization = 'Bearer ' + s.access_token;
  if (qb && qb.headers) Object.assign(h, qb.headers);
  return h;
}

})();
