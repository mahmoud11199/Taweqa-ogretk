import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Authorization, Content-Type, x-webhook-secret',
};

interface SmsPayload {
  sender?: string;
  message?: string;
  timestamp?: string;
}

// Parse incoming SMS from Egyptian mobile wallets.
// Returns normalized sender phone, amount, and optional transaction reference.
function parseSms(sender: string, message: string): {
  senderPhone: string;
  amount: number | null;
  transactionId: string | null;
} {
  const normalized = (raw: string): string => {
    const digits = (raw || '').replace(/[^\d]/g, '');
    if (digits.startsWith('20') && digits.length === 13) return '0' + digits.slice(2);
    if (digits.length === 13 && digits.startsWith('2')) return '0' + digits.slice(2);
    return digits;
  };

  // Egyptian phone numbers: 01[0-9]{9}
  const phoneMatch = (message + ' ' + sender).match(/01[0-9]{9}/);
  const senderPhone = normalized(phoneMatch ? phoneMatch[0] : sender) || '';

  // Amount: look for number preceded by EGP / جنيه / LE / LE. / "amount"
  let amount: number | null = null;
  const amountPatterns = [
    /(?:EGP|LE|E£|ج\.م|جنيه|جنيه مصري|المبلغ|المدفوع|قيمة التحويل)[^\d-]*([\d.,]+)/i,
    /([\d.,]+)\s*(?:EGP|LE|E£|ج\.م|جنيه)/i,
    /(?:amount|فودافون كاش|أورنج كاش|اتصالات كاش|وي باي|instapay)[^\d-]*([\d.,]+)/i,
  ];
  for (const pattern of amountPatterns) {
    const m = message.match(pattern);
    if (m) {
      const parsed = parseFloat(m[1].replace(/,/g, ''));
      if (!isNaN(parsed) && parsed > 0) { amount = parsed; break; }
    }
  }

  // Transaction reference: common keywords
  const refMatch = message.match(
    /(?:ref(?:erence)?\.?[: ]|رقم العملية|رقم الحوالة|المرجع|transaction(?:\s*(?:id|no|number))?[: ])([A-Z0-9]+)/i,
  );
  const transactionId = refMatch ? refMatch[1] : null;

  return { senderPhone, amount, transactionId };
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // Secret header check
  const secret = Deno.env.get('SMS_WEBHOOK_SECRET') || '';
  const headerSecret = req.headers.get('x-webhook-secret') || '';
  if (!secret || headerSecret !== secret) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  let body: SmsPayload;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid JSON' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const sender = body.sender || '';
  const message = body.message || '';
  if (!sender || !message) {
    return new Response(JSON.stringify({ error: 'sender and message are required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const { senderPhone, amount, transactionId } = parseSms(sender, message);
  if (!senderPhone || amount === null || amount <= 0) {
    return new Response(JSON.stringify({ error: 'Could not parse SMS', senderPhone, amount }), {
      status: 422,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // Fallback deterministic reference when SMS has no explicit one
  const ref = transactionId || (sender + ':' + message).replace(/[^\w:]/g, '').slice(-24);

  const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
  if (!supabaseUrl || !serviceRoleKey) {
    return new Response(JSON.stringify({ error: 'Server misconfigured' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey);

  try {
    const { data, error } = await supabase.rpc('confirm_wallet_deposit', {
      p_transaction_id: ref,
      p_sender_phone: senderPhone,
      p_amount: amount,
      p_raw_sms: message,
    });

    if (error) {
      console.error('RPC error:', error);
      // Unique violation => already processed
      if (error.code === '23505') {
        return new Response(JSON.stringify({ success: false, code: 'ALREADY_PROCESSED' }), {
          status: 409,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }
      return new Response(JSON.stringify({ success: false, error: error.message }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const result = (data || {}) as { success?: boolean; code?: string; wallet_transaction_id?: string };

    if (result.success) {
      return new Response(JSON.stringify(result), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (result.code === 'ALREADY_PROCESSED') {
      return new Response(JSON.stringify(result), {
        status: 409,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // NO_MATCH => store as unmatched, but respond 202 (accepted, pending manual review)
    return new Response(JSON.stringify(result), {
      status: 202,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (e) {
    console.error('Webhook error:', e);
    return new Response(JSON.stringify({ success: false, error: 'Internal error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
