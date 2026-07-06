import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  const url = new URL(req.url);
  const hash = url.hash || '';
  const params = new URLSearchParams(hash.replace('#', ''));

  const accessToken = params.get('access_token');
  const refreshToken = params.get('refresh_token');
  const type = params.get('type');

  const baseUrl = 'https://mahmoud11199.github.io/Taweqa-ogretk';

  if (type === 'recovery' && accessToken) {
    const redirectUrl = baseUrl + '/recovery.html#' + hash.replace('#', '');
    return Response.redirect(redirectUrl, 302);
  }

  if (type === 'signup' && accessToken) {
    const redirectUrl = baseUrl + '/#' + hash.replace('#', '');
    return Response.redirect(redirectUrl, 302);
  }

  return Response.redirect(baseUrl + '/', 302);
});
