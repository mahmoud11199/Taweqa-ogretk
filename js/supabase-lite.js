(function() {
var STORAGE_KEY = 'taweqe_sb_session';

function loadSession() {
  try { var d = JSON.parse(localStorage.getItem(STORAGE_KEY)); if (d && d.access_token && d.expires_at > Date.now() / 1000) return d; } catch(e) {}
  return null;
}
function saveSession(s) {
  if (!s) return;
  try {
    s.expires_at = s.expires_at || (Date.now() / 1000 + (s.expires_in || 3600));
    localStorage.setItem(STORAGE_KEY, JSON.stringify(s));
  } catch(e) {}
}
function clearSession() {
  try { localStorage.removeItem(STORAGE_KEY); } catch(e) {}
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
  function handleResp(resp) {
    if (resp.error) return { data: null, error: resp.error };
    if (resp.data && resp.data.access_token) saveSession(resp.data);
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
      if (s && s.access_token) {
        return sbFetch(authUrl + '/logout', {
          method: 'POST', headers: Object.assign({}, gh, { Authorization: 'Bearer ' + s.access_token })
        }).then(function() { clearSession(); return { error: null }; });
      }
      clearSession();
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
    onAuthStateChange: function(cb) {
      var id = Date.now() + '_' + Math.random();
      var unsub = function() {};
      return { data: { subscription: { id: id, unsubscribe: unsub } } };
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
    var h = { apikey: anonKey, Prefer: 'return=representation' };
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
      if (query.singleResult || query.maybeSingleResult) params += '&limit=1';
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
        var h = { apikey: anonKey, Prefer: 'resolution=merge-duplicates' };
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
        var h = { apikey: anonKey, Prefer: 'return=representation' };
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
    channel: function() { return { subscribe: function(cb) { if (cb) cb('SUBSCRIBED'); return { unsubscribe: function() {} }; } }; },
    getChannels: function() { return []; },
    removeChannel: function() {},
    removeAllChannels: function() {}
  };

  return client;
};

function getAuthHeaders(qb) {
  var s = loadSession();
  var h = { apikey: qb.apikey || '', Prefer: 'return=representation' };
  if (s && s.access_token) h.Authorization = 'Bearer ' + s.access_token;
  if (qb && qb.headers) Object.assign(h, qb.headers);
  return h;
}

})();
