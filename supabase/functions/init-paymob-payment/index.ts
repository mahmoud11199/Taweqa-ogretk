import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Authorization, Content-Type',
};

const PAYMOB_API_KEY = Deno.env.get('PAYMOB_API_KEY') || '';
const PAYMOB_IFRAME_ID = Deno.env.get('PAYMOB_IFRAME_ID') || '';

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { amount, email, phone, first_name, last_name } = await req.json();

    if (typeof amount !== 'number' || amount <= 0) {
      return new Response(
        JSON.stringify({ error: 'Invalid amount' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    if (PAYMOB_API_KEY && PAYMOB_API_KEY !== '') {
      const amountCents = Math.round(amount * 100);
      const PAYMOB_INTEGRATION_ID = Deno.env.get('PAYMOB_INTEGRATION_ID') || '';

      const authRes = await fetch('https://accept.paymobsolutions.com/api/auth/tokens', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ api_key: PAYMOB_API_KEY }),
      });
      const auth = await authRes.json();
      const token = auth['token'] as string;

      const orderRes = await fetch('https://accept.paymobsolutions.com/api/ecommerce/orders', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
        body: JSON.stringify({
          auth_token: token,
          delivery_needed: 'false',
          amount_cents: amountCents,
          currency: 'EGP',
          items: [],
        }),
      });
      const order = await orderRes.json();
      const orderId = order['id'] as number;

      const paymentRes = await fetch('https://accept.paymobsolutions.com/api/acceptance/payment_keys', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
        body: JSON.stringify({
          auth_token: token,
          amount_cents: amountCents,
          expiration: 3600,
          order_id: orderId,
          billing_data: {
            apartment: 'NA',
            email: email || 'user@example.com',
            floor: 'NA',
            first_name: first_name || 'User',
            street: 'NA',
            building: 'NA',
            phone_number: phone || '01000000000',
            shipping_method: 'NA',
            postal_code: 'NA',
            city: 'NA',
            country: 'EG',
            last_name: last_name || 'NA',
            state: 'NA',
          },
          currency: 'EGP',
          integration_id: parseInt(PAYMOB_INTEGRATION_ID),
          lock_order_when_paid: 'false',
        }),
      });
      const payment = await paymentRes.json();
      const paymentKey = payment['token'] as string;

      return new Response(
        JSON.stringify({ payment_key: paymentKey, iframe_id: PAYMOB_IFRAME_ID }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const mockPaymentKey = `mock_pk_${Date.now()}`;
    return new Response(
      JSON.stringify({
        payment_key: mockPaymentKey,
        iframe_id: PAYMOB_IFRAME_ID || 'mock_iframe',
        mock: true,
        message: '⚠️ Paymob غير مهيأ — هذه استجابة تجريبية. اضبط PAYMOB_API_KEY في Supabase Secrets.',
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : 'Unknown error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
