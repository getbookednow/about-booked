// Public presentation settings only. Never put API keys or webhook secrets here.
window.BOOKED_PRODUCTIONS = {
  // Verified public receiver. Local previews retain WhatsApp; production accepts only these origins.
  // Activate the Make scenario before releasing this website change.
  enquiryEndpoint: ['bookednow.co.za', 'www.bookednow.co.za'].includes(window.location.hostname)
    ? 'https://booked-production-enquiries.luca-a74.workers.dev/api/production-enquiry'
    : '',
  whatsappNumber: '27637549122',
  // Add priced bands only when approved. No assumed package pricing.
  budgetOptions: ['To be discussed', 'Budget not yet set'],
  destinations: [
    { id: 'cape-town', name: 'Cape Town, South Africa', status: 'enquiry', description: 'Creative production planning in Cape Town.', gallery: [], capabilities: ['Location research', 'Production coordination'], creativePartners: [], accommodationPartners: [], experiences: ['Destination productions', 'Creative residencies', 'Brand retreats'] },
    { id: 'milan', name: 'Milan, Italy', status: 'not-launched', gallery: [], capabilities: [], creativePartners: [], accommodationPartners: [], experiences: [] },
    { id: 'bali', name: 'Bali, Indonesia', status: 'not-launched', gallery: [], capabilities: [], creativePartners: [], accommodationPartners: [], experiences: [] }
  ]
};
