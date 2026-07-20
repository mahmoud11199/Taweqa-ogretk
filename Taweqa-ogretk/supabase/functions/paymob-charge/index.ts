import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const PAYMOB_AUTH_URL = 'https://accept.paymob.com/api/auth/tokens';
const PAYMOB_INTENTION_URL = 'https://accept.paymob.com/v1/intention/';
const PAYMOB_QUERY_URL = 'https://accept.paymob.com/v1/intention';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

async function getPaymobToken(): Promise<string> {
  const apiKey = Deno.env.get('PAYMOB_API_KEY');
  if (!apiKey) throw new Error('PAYMOB_API_KEY not configured');
  const res = await fetch(PAYMOB_AUTH_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ api_key: apiKey }),
  });
  const data = await res.json();
  if (!data.token) throw new Error('Paymob auth failed: ' + JSON.stringify(data));
  return data.token;
}

async function handleCreate(amount: number, userId: string, userEmail: string, userName: string, userPhone: string, supabaseUrl: string): Promise<{ redirect_url: string; intention_id: string }> {
  const token = await getPaymobToken();
  const integrationId = Deno.env.get('PAYMOB_INTEGRATION_ID');
  if (!integrationId) throw new Error('PAYMOB_INTEGRATION_ID not configured');

  const notificationUrl = `${supabaseUrl}/functions/v1/paymob-charge`;
  const siteUrl = Deno.env.get('SITE_URL') || supabaseUrl.replace('.supabase.co', '.netlify.app');
  const redirectUrl = `${siteUrl}/?paymob_callback=1`;

  const body = {
    amount: amount,
    currency: 'EGP',
    payment_methods: [parseInt(integrationId)],
    items: [{
      name: 'شحن محفظة توقع أجرتك',
      amount: amount,
      quantity: 1,
      description: 'شحن رصيد المحفظة الإلكترونية',
    }],
    billing_data: {
      first_name: userName || 'مستخدم',
      last_name: '',
      email: userEmail || '',
      phone_number: userPhone || '',
      country: 'EG',
      city: '',
      state: '',
      street: '',
      building: '',
      floor: '',
      apartment: '',
    },
    notification_url: notificationUrl,
    redirect_url: redirectUrl,
  };

  const res = await fetch(PAYMOB_INTENTION_URL, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const data = await res.json();
  if (!data.id) throw new Error('Paymob intention failed: ' + JSON.stringify(data));

  return { redirect_url: `https://accept.paymob.com/v1/intention/${data.client_secret}/pay`, intention_id: String(data.id) };
}

async function handleVerify(intentionId: string, userId: string, supabaseUrl: string, serviceRoleKey: string): Promise<{ success: boolean; balance?: number; error?: string }> {
  const token = await getPaymobToken();

  const res = await fetch(`${PAYMOB_QUERY_URL}/${intentionId}`, {
    headers: { 'Authorization': `Bearer ${token}` },
  });
  const data = await res.json();

  const isPaid = data.status === 'success' || data.status === 'paid' || data.is_paid === true || data.payment_status === 'paid';
  if (!isPaid) return { success: false, error: `Payment not completed. Status: ${data.status || 'unknown'}` };

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: existingTx, error: txError } = await admin
    .from('wallet_transactions')
    .select('id, status')
    .eq('reference_id', intentionId)
    .maybeSingle();

  if (existingTx && existingTx.status === 'completed') {
    return { success: true, error: 'already_completed' };
  }

  if (existingTx && existingTx.status !== 'completed') {
    await admin.from('wallet_transactions').update({ status: 'completed' }).eq('id', existingTx.id);
    await admin.rpc('apply_wallet_charge', { p_user_id: userId, p_amount: data.amount });
    return { success: true };
  }

  await admin.from('wallet_transactions').insert({
    user_id: userId, amount: data.amount, type: 'charge', status: 'completed',
    reference_id: intentionId, description: `شحن المحفظة عبر Paymob - ${data.amount} ج`,
  });
  await admin.rpc('apply_wallet_charge', { p_user_id: userId, p_amount: data.amount });

  return { success: true };
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return jsonResponse({ error: 'Method not allowed' }, 405);

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

    const authHeader = req.headers.get('Authorization') || '';
    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data: authData, error: authError } = await admin.auth.getUser(authHeader.replace('Bearer ', ''));
    if (authError || !authData.user) return jsonResponse({ error: 'Unauthorized' }, 401);

    const body = await req.json().catch(() => null) as { action?: string; amount?: number; intention_id?: string } | null;
    if (!body || !body.action) return jsonResponse({ error: 'Missing action parameter' }, 400);

    if (body.action === 'create') {
      if (!body.amount || body.amount < 10) return jsonResponse({ error: 'Minimum amount is 10 EGP' }, 400);

      const user = authData.user;
      const email = user.email || '';
      const { data: profile } = await admin.from('profiles').select('full_name, phone').eq('id', user.id).single();
      const name = profile?.full_name || '';
      const phone = profile?.phone || '';

      const result = await handleCreate(body.amount, user.id, email, name, phone, supabaseUrl);

      await admin.from('wallet_transactions').insert({
        user_id: user.id, amount: body.amount, type: 'charge', status: 'pending',
        reference: result.intention_id, description: `شحن المحفظة - في انتظار الدفع (${body.amount} ج)`,
      });

      return jsonResponse(result);
    }

    if (body.action === 'verify') {
      if (!body.intention_id) return jsonResponse({ error: 'Missing intention_id' }, 400);
      const result = await handleVerify(body.intention_id, authData.user.id, supabaseUrl, serviceRoleKey);
      return jsonResponse(result);
    }

    return jsonResponse({ error: 'Unknown action' }, 400);
  } catch (e) {
    return jsonResponse({ error: e instanceof Error ? e.message : 'Internal error' }, 500);
  }
});
