// Supabase Edge Function: auth-callback
// Handles post-password-reset redirect from Supabase Auth

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';

serve(async (req) => {
  const url = new URL(req.url);
  const type = url.searchParams.get('type');
  const accessToken = url.searchParams.get('access_token');

  if (type === 'recovery' && accessToken) {
    // Redirect user to the app with the recovery token
    const appUrl = `taweqa-ogretk://reset-password?access_token=${accessToken}`;
    return Response.redirect(appUrl, 302);
  }

  // Fallback: redirect to web app
  return Response.redirect('https://mahmoud11199.github.io/Taweqa-ogretk', 302);
});
