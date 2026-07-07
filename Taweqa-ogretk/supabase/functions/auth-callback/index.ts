const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  const baseUrl = Deno.env.get('SITE_URL') || 'https://mahmoud11199.github.io/Taweqa-ogretk';

  const html = `<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>توجيه...</title>
  <style>
    body {
      font-family: system-ui, -apple-system, sans-serif;
      background: #0f172a;
      color: #fff;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      margin: 0;
      text-align: center;
      direction: rtl;
    }
    .box {
      background: rgba(255,255,255,0.05);
      border: 1px solid rgba(255,255,255,0.1);
      border-radius: 20px;
      padding: 32px 24px;
      max-width: 360px;
      width: 100%;
    }
    .spinner {
      display: inline-block;
      width: 32px;
      height: 32px;
      border: 4px solid rgba(255,255,255,0.15);
      border-top-color: #22d3ee;
      border-radius: 50%;
      animation: spin 0.7s linear infinite;
      margin-bottom: 12px;
    }
    @keyframes spin { to { transform: rotate(360deg); } }
    p { color: #94a3b8; font-size: 14px; margin: 0; }
  </style>
</head>
<body>
  <div class="box">
    <div class="spinner"></div>
    <p>جاري توجيهك...</p>
  </div>
  <script>
    (function() {
      var hash = window.location.hash;
      var params = {};
      if (hash) {
        hash.replace('#', '').split('&').forEach(function(p) {
          var kv = p.split('=');
          if (kv.length === 2) params[decodeURIComponent(kv[0])] = decodeURIComponent(kv[1]);
        });
      }
      var type = params.type || '';
      var target = '${baseUrl}/';
      if (type === 'recovery') {
        target = '${baseUrl}/recovery.html' + hash;
      } else if (hash) {
        target = '${baseUrl}/' + hash;
      }
      window.location.replace(target);
    })();
  </script>
</body>
</html>`;

  return new Response(html, {
    status: 200,
    headers: {
      ...corsHeaders,
      'Content-Type': 'text/html; charset=utf-8',
    },
  });
});
