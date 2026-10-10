const TYPES = ['Fashion campaign', 'Editorial shoot', 'Lookbook production', 'Creative residency', 'Brand retreat', 'Other'];
const SERVICES = ['Location research', 'Production coordination', 'Talent and suppliers', 'Accommodation coordination', 'Transport and logistics', 'Workshops and collaboration'];
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
export function validate(input) {
  if (!input || typeof input !== 'object' || Array.isArray(input)) throw Error('Invalid request.');
  const text = (key, max, required = false) => {
    if (input[key] == null && !required) return '';
    if (typeof input[key] !== 'string') throw Error('Please check ' + key + '.');
    const value = input[key].trim();
    if (value.length > max || (required && !value) || /[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/.test(value)) throw Error('Please check ' + key + '.');
    return value;
  };
  if (input.website) throw Error('Please leave the website field empty.');
  if (!UUID.test(input.submission_id)) throw Error('Please refresh the page and try again.');
  const full_name = text('full_name', 100, true), email = text('email', 254, true);
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) throw Error('Please check your email address.');
  const project_description = text('project_description', 1200, true);
  if (project_description.length < 20) throw Error('Please describe your project in at least 20 characters.');
  if (!TYPES.includes(input.project_type) || input.destination !== 'Cape Town, South Africa') throw Error('Please check the project type and destination.');
  if (input.consent_to_contact !== true || input.consent_version !== 'productions-v1') throw Error('Contact consent is required.');
  if (!Array.isArray(input.required_services) || input.required_services.length > SERVICES.length || input.required_services.some(s => !SERVICES.includes(s))) throw Error('Please check required services.');
  const team = input.team_size;
  if (team !== null && (!Number.isInteger(team) || team < 1 || team > 10000)) throw Error('Please check team size.');
  if (typeof input.consent_at !== 'string' || !/^\d{4}-\d{2}-\d{2}T/.test(input.consent_at) || !Number.isFinite(Date.parse(input.consent_at)) || Math.abs(Date.now() - Date.parse(input.consent_at)) > 86400000) throw Error('Please review your enquiry again.');
  return {submission_id:input.submission_id, full_name, company:text('company',120), email, phone:text('phone',40), project_type:input.project_type, destination:input.destination, preferred_dates:text('preferred_dates',120), team_size:team, budget_range:text('budget_range',100), budget_detail:text('budget_detail',100), required_services:[...new Set(input.required_services)], project_description, consent_to_contact:true, consent_version:'productions-v1', consent_at:input.consent_at, received_at:new Date().toISOString(), source:'booked-productions', schema_version:1};
}
export function createHandler(upstreamFetch = (url, options) => fetch(url, options)) {
  return async (request, env) => {
    const origin = request.headers.get('Origin');
    const allowed = (env.ALLOWED_ORIGINS || '').split(',').map(s => s.trim());
    const headers = {'Content-Type':'application/json','Cache-Control':'no-store','Vary':'Origin','X-Content-Type-Options':'nosniff'};
    const reply = (status, body) => new Response(JSON.stringify(body), {status,headers});
    if (!origin || !allowed.includes(origin)) return reply(403,{ok:false,message:'This website is not allowed to submit enquiries.'});
    headers['Access-Control-Allow-Origin'] = origin;
    headers['Access-Control-Allow-Methods'] = 'POST, OPTIONS';
    headers['Access-Control-Allow-Headers'] = 'Content-Type';
    if (new URL(request.url).pathname !== '/api/production-enquiry') return reply(404,{ok:false});
    if (request.method === 'OPTIONS') return new Response(null,{status:204,headers});
    if (request.method !== 'POST') return reply(405,{ok:false,message:'Use the enquiry form.'});
    if (!/^application\/json(?:;|$)/i.test(request.headers.get('Content-Type') || '')) return reply(415,{ok:false,message:'Invalid submission format.'});
    if (!env.ENQUIRY_RATE_LIMITER || !env.MAKE_WEBHOOK_URL) return reply(503,{ok:false,message:'Enquiries are temporarily unavailable. Please use WhatsApp.'});
    const ip = request.headers.get('CF-Connecting-IP');
    if (!ip) return reply(503,{ok:false,message:'Enquiries are temporarily unavailable.'});
    let webhook;
    try { webhook = new URL(env.MAKE_WEBHOOK_URL); } catch { return reply(503,{ok:false,message:'Enquiries are temporarily unavailable.'}); }
    if (webhook.protocol !== 'https:' || !/^hook\.(?:eu\d+\.|us\d+\.)?make\.com$/.test(webhook.hostname) || webhook.username || webhook.password) return reply(503,{ok:false,message:'Enquiries are temporarily unavailable.'});
    let payload, stage = 'rate_limit';
    try {
      const limit = await env.ENQUIRY_RATE_LIMITER.limit({key:ip});
      if (!limit.success) return reply(429,{ok:false,message:'Too many attempts. Wait a minute and try again.'});
      if (Number(request.headers.get('Content-Length')) > 16000) return reply(413,{ok:false,message:'Your enquiry is too large.'});
      const reader = request.body?.getReader();
      if (!reader) return reply(400,{ok:false,message:'Your enquiry is empty.'});
      let size = 0; const chunks = [];
      for (;;) {
        const {done,value} = await reader.read(); if (done) break;
        size += value.byteLength;
        if (size > 16000) { await reader.cancel(); return reply(413,{ok:false,message:'Your enquiry is too large.'}); }
        chunks.push(value);
      }
      const bytes = new Uint8Array(size);let offset=0;for(const chunk of chunks){bytes.set(chunk,offset);offset+=chunk.length;}
      try { payload=validate(JSON.parse(new TextDecoder().decode(bytes))); } catch(error){return reply(400,{ok:false,message:error instanceof SyntaxError?'Invalid submission format.':error.message});}
      stage = 'timeout';
      const signal = AbortSignal.timeout(20000);
      stage = 'forward';
      const response=await upstreamFetch(webhook.toString(),{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(payload),signal,redirect:'manual'});
      // Make's default "Accepted" response only means queued, not saved.
      const receipt=await response.json().catch(()=>null);
      if (!response.ok || receipt?.ok !== true || receipt.submission_id !== payload.submission_id) return reply(502,{ok:false,message:'Saving could not be confirmed. Retry this brief; the reference stays the same.'});
      return reply(200,{ok:true,submission_id:payload.submission_id});
    } catch (error) {
      const reason = /Illegal invocation/i.test(error?.message || '') ? 'invocation' : /redirect/i.test(error?.message || '') ? 'redirect' : /AbortSignal|timeout/i.test(error?.message || '') ? 'timeout' : 'other';
      console.warn({event:'enquiry_failure',stage,error_type:error?.name || 'Error',reason});
      return reply(503,{ok:false,message:'Saving could not be confirmed. Retry this brief; the reference stays the same.'});
    }
  };
}
export default {fetch:createHandler()};
