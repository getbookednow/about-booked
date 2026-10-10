'use strict';
(() => {
  const form = document.getElementById('production-enquiry');
  const review = document.getElementById('brief-review');
  const error = document.getElementById('form-error');
  const config = window.BOOKED_PRODUCTIONS;
  if (!form || !config) return;
  const destination = document.getElementById('destination');
  const budget = document.getElementById('budget');
  destination.replaceChildren(...config.destinations.filter(d => d.status === 'enquiry').map(d => new Option(d.name, d.name)));
  budget.replaceChildren(...config.budgetOptions.map(b => new Option(b, b)));
  if (!destination.options.length || !/^\d{8,15}$/.test(config.whatsappNumber)) {
    document.getElementById('delivery-note').textContent = 'The brief builder is unavailable. Please contact luca@bookednow.co.za about your project.';
    return;
  }
  form.hidden = false;
  const endpoint = config.enquiryEndpoint;
  const submitButton = document.getElementById('submit-enquiry');
  const status = document.getElementById('submission-status');
  let payload = null, submitted = false, sending = false;
  if (endpoint) {
    let url;
    try { url = new URL(endpoint, location.origin); } catch { return; }
    if (url.protocol !== 'https:' && url.hostname !== '127.0.0.1' && url.hostname !== 'localhost') return;
    document.getElementById('delivery-note').textContent = 'Review your brief, then send it securely to BOOKED. Your enquiry is saved in Make so we can respond about this project.';
    document.getElementById('review-delivery-note').textContent = 'Not sent yet. Send your project enquiry below. WhatsApp is also available if you prefer.';
    submitButton.hidden = false;
  }
  let brief = '';
  form.addEventListener('submit', event => {
    event.preventDefault();
    error.textContent = '';
    const data = new FormData(form);
    if (data.get('website')) { error.textContent = 'Please leave the website field empty and try again.'; return; }
    for (const name of ['name', 'email', 'description']) {
      const field = form.elements.namedItem(name);
      field.value = field.value.trim();
      field.setCustomValidity(name === 'description' && field.value.length < 20 ? 'Please describe your project in at least 20 characters.' : !field.value ? 'Please complete this field.' : '');
    }
    if (!form.reportValidity()) return;
    const values = new FormData(form);
    const read = name => String(values.get(name) || '').trim();
    const lines = [
      'BOOKED. / PRODUCTIONS — PROJECT ENQUIRY',
      ['Full name', read('name')], ['Company / agency / collective', read('company')],
      ['Email', read('email')], ['Phone', read('phone')], ['Project type', read('type')],
      ['Destination', read('destination')], ['Preferred dates', read('dates')],
      ['Team size', read('team')], ['Estimated budget', read('budget')],
      ['Budget detail', read('budgetDetail')], ['Required services', values.getAll('services').join(', ')],
      ['Project description', read('description')],
      ['Contact consent', 'Yes — contact me about this project only.']
    ];
    const snapshot = {
      full_name:read('name'), company:read('company'), email:read('email'), phone:read('phone'),
      project_type:read('type'), destination:read('destination'), preferred_dates:read('dates'),
      team_size:read('team') ? Number(read('team')) : null, budget_range:read('budget'), budget_detail:read('budgetDetail'),
      required_services:values.getAll('services'), project_description:read('description'),
      consent_to_contact:values.get('consent') === 'on', consent_version:'productions-v1', website:read('website')
    };
    const previous = payload && Object.fromEntries(Object.entries(payload).filter(([key]) => !['submission_id','consent_at'].includes(key)));
    if (!previous || submitted || JSON.stringify(previous) !== JSON.stringify(snapshot)) {
      payload = {...snapshot, submission_id:crypto.randomUUID(), consent_at:new Date().toISOString()};
    }
    submitted = false;
    submitButton.disabled = false;
    submitButton.textContent = 'Send project enquiry →';
    status.textContent = '';
    brief = lines.map(line => Array.isArray(line) ? line[0] + ': ' + (line[1] || 'Not specified') : line).join('\n\n');
    document.getElementById('brief-text').textContent = brief;
    document.getElementById('send-brief').href = 'https://wa.me/' + config.whatsappNumber + '?text=' + encodeURIComponent(brief);
    document.getElementById('copy-status').textContent = '';
    form.hidden = true;
    review.hidden = false;
    document.getElementById('review-title').focus();
  });
  for (const name of ['name', 'email', 'description']) {
    form.elements.namedItem(name).addEventListener('input', event => event.target.setCustomValidity(''));
  }
  submitButton.addEventListener('click', async () => {
    if (sending || submitted || !endpoint || !payload) return;
    sending = true;
    submitButton.disabled = true;
    document.getElementById('edit-brief').disabled = true;
    submitButton.textContent = 'Sending…';
    status.textContent = 'Saving your project enquiry…';
    try {
      const response = await fetch(endpoint, {
        method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify(payload),
        credentials:'omit', referrerPolicy:'no-referrer', signal:AbortSignal.timeout(25000)
      });
      const receipt = await response.json();
      if (!response.ok || receipt.ok !== true || receipt.submission_id !== payload.submission_id) throw new Error(receipt.message || 'Saving could not be confirmed. Try again or use WhatsApp.');
      submitted = true;
      status.textContent = 'Enquiry saved. Your reference is ' + payload.submission_id + '. BOOKED. can now review your project.';
      submitButton.textContent = 'Enquiry saved';
      document.getElementById('review-delivery-note').textContent = 'Your enquiry is saved in Make. You can still use WhatsApp if you need to add anything.';
      status.focus();
    } catch (err) {
      status.textContent = err.name === 'TimeoutError' || err.name === 'TypeError' ? 'Saving could not be confirmed. Retry this brief, or use WhatsApp. Your details are still here.' : err.message;
      submitButton.disabled = false;
      submitButton.textContent = 'Retry project enquiry →';
    } finally {
      sending = false;
      document.getElementById('edit-brief').disabled = false;
    }
  });
  document.getElementById('edit-brief').addEventListener('click', () => {
    review.hidden = true;
    form.hidden = false;
    document.getElementById('review-delivery-note').textContent = endpoint ? 'Not sent yet. Send your project enquiry below. WhatsApp is also available if you prefer.' : 'Not sent yet. Opening WhatsApp shares this text with WhatsApp. Press Send there to deliver it to BOOKED.';
    form.elements.namedItem('name').focus();
  });
  document.getElementById('copy-brief').addEventListener('click', async () => {
    const status = document.getElementById('copy-status');
    try {
      await navigator.clipboard.writeText(brief);
      status.textContent = 'Copied. Paste it into your message to BOOKED. Nothing has been sent.';
    } catch {
      status.textContent = 'Copy is unavailable. Select the brief above and copy it manually, or open WhatsApp.';
    }
  });
})();
