import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Authorization, Content-Type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  const url = new URL(req.url);
  const type = url.searchParams.get('type');
  const accessToken = url.searchParams.get('access_token');

  if (type === 'recovery' && accessToken) {
    const appUrl = `taweqa-ogretk://reset-password?access_token=${accessToken}`;
    return Response.redirect(appUrl, 302);
  }

  return Response.redirect('https://mahmoud11199.github.io/Taweqa-ogretk', 302);
});
