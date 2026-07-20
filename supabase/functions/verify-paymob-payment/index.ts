import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const PAYMOB_QUERY_URL = 'https://accept.paymob.com/v1/intention';
const PAYMOB_AUTH_URL = 'https://accept.paymob.com/api/auth/tokens';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const apiKey = Deno.env.get('PAYMOB_API_KEY');

    const authHeader = req.headers.get('Authorization') || '';
    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data: authData, error: authError } = await supabase.auth.getUser(authHeader.replace('Bearer ', ''));
    if (authError || !authData.user) {
      return new Response(JSON.stringify({ success: false, error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const body = await req.json() as { transaction_ref?: string };
    const transactionRef = body.transaction_ref;
    if (!transactionRef) {
      return new Response(JSON.stringify({ success: false, error: 'Missing transaction_ref' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (!apiKey) {
      return new Response(JSON.stringify({ success: true, mock: true, message: 'Paymob غير مهيأ — تم اعتبار الدفع ناجحاً تجريبياً' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const authRes = await fetch(PAYMOB_AUTH_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ api_key: apiKey }),
    });
    const auth = await authRes.json();
    const token = auth.token as string;

    const queryRes = await fetch(`${PAYMOB_QUERY_URL}/${transactionRef}`, {
      headers: { 'Authorization': `Bearer ${token}` },
    });
    const data = await queryRes.json();

    const isPaid = data.status === 'success' || data.status === 'paid' ||
                   data.is_paid === true || data.payment_status === 'paid';

    if (isPaid) {
      const { data: existingTx, error: txError } = await supabase
        .from('wallet_transactions')
        .select('id, status')
        .eq('reference_id', transactionRef)
        .maybeSingle();

      if (existingTx && existingTx.status !== 'completed') {
        await supabase.from('wallet_transactions').update({ status: 'completed' }).eq('id', existingTx.id);
        await supabase.rpc('apply_wallet_charge', { p_user_id: authData.user.id, p_amount: data.amount });
      } else if (!existingTx && !txError) {
        await supabase.from('wallet_transactions').insert({
          user_id: authData.user.id, amount: data.amount, type: 'charge', status: 'completed',
          reference_id: transactionRef, description: `شحن المحفظة عبر Paymob - ${data.amount} ج`,
        });
        await supabase.rpc('apply_wallet_charge', { p_user_id: authData.user.id, p_amount: data.amount });
      }

      return new Response(JSON.stringify({ success: true }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    return new Response(JSON.stringify({ success: false, error: 'لم يتم تأكيد الدفع بعد' }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err) {
    return new Response(JSON.stringify({
      success: false,
      error: err instanceof Error ? err.message : 'Internal error',
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
