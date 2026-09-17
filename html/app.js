'use strict';
const viewer = document.getElementById('viewer');
let labels = {};
window.addEventListener('message', ({ data }) => {
  if (!data || !['open', 'close'].includes(data.action)) return;
  if (data.action === 'close') { viewer.hidden = true; return; }
  if (!data.card || !data.labels) return;
  labels = data.labels;
  document.documentElement.lang = String(data.language || 'nl');
  document.title = String(labels.title || '');
  document.querySelector('.card').setAttribute('aria-label', String(labels.aria || ''));
  document.querySelector('.art').alt = String(labels.art_alt || '');
  for (const element of document.querySelectorAll('[data-label]')) {
    element.textContent = String(labels[element.dataset.label] || '');
  }
  for (const key of ['name', 'rank', 'station']) {
    document.getElementById(key).textContent = String(data.card[key] ?? labels.unknown ?? '');
  }
  viewer.hidden = false;
  document.getElementById('close').focus();
});
async function closeCard() {
  viewer.hidden = true;
  if (typeof GetParentResourceName !== 'function') return;
  try {
    await fetch(`https://${GetParentResourceName()}/close`, {
      method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' }, body: '{}'
    });
  } catch (error) { console.error(labels.close_failed || 'close_failed', error); }
}
document.getElementById('close').addEventListener('click', closeCard);
document.addEventListener('keydown', (event) => { if (event.key === 'Escape') closeCard(); });
